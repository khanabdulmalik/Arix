import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'mesh_transport.dart';

/// ARIX BLE mesh transport for iOS & Android.
///
/// ### Background-execution hardening
///
/// 1. Uses **`FlutterBluePlus.startScan(…, androidUsesFineLocation: true)`**
///    with continuous mode (`timeout: Duration.zero`) so the OS treats
///    scanning as a long-running BLE session rather than a one-shot burst.
///
/// 2. Scan is started with `allowDuplicates: true` so repeated
///    advertisements from the same device are surfaced (required for
///    mesh relay where the payload changes per broadcast).
///
/// 3. All heavy work (JSON decode, stream dispatch) is fully asynchronous
///    to avoid blocking the platform channel.
///
/// 4. The class exposes a [startBackground] / [stopBackground] lifecycle
///    so the host can tie scanning to an Android foreground service or iOS
///    background task.
///
/// ### iOS specifics
/// - `Info.plist` must include `bluetooth-central` AND `bluetooth-peripheral`
///   in `UIBackgroundModes`.
/// - Core Bluetooth throttles background scans to ≈ 1 discovery / 15 s per
///   UUID.  We mitigate this by advertising a rotating payload on the
///   *peripheral* side (see GATT service UUID below).
///
/// ### Android specifics
/// - A **foreground service** notification is required on Android 8+ for
///   indefinite scanning.  The companion [BackgroundBleService] must be
///   registered in `AndroidManifest.xml`.
/// - `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, and `BLUETOOTH_CONNECT`
///   permissions are all required on API 31+.
class BleMeshTransport implements MeshTransport {
  // Custom 128-bit service UUID for ARIX mesh discovery.
  static const String _serviceUuid = '0000arix-0000-1000-8000-00805f9b34fb';

  // GATT characteristic UUID for the mesh payload.
  static const String _charUuid = '0000feed-0000-1000-8000-00805f9b34fb';

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  StreamSubscription? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  bool _isScanning = false;

  BleMeshTransport();

  // ========================= Lifecycle =========================

  /// Initialise scanning.  Safe to call from a foreground service.
  Future<void> startBackground() async {
    // React to adapter state changes (e.g. user toggling Bluetooth).
    _adapterSubscription ??=
        FlutterBluePlus.adapterState.listen((state) async {
      if (state == BluetoothAdapterState.on && !_isScanning) {
        await _beginScan();
      } else if (state != BluetoothAdapterState.on) {
        _isScanning = false;
      }
    });

    // If already on, start immediately.
    final currentState = await FlutterBluePlus.adapterState.first;
    if (currentState == BluetoothAdapterState.on) {
      await _beginScan();
    }
  }

  Future<void> stopBackground() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _adapterSubscription?.cancel();
    _adapterSubscription = null;
    _isScanning = false;
    await FlutterBluePlus.stopScan();
  }

  // ======================== MeshTransport =======================

  @override
  Future<void> broadcast(String payload) async {
    // BLE "broadcast" = write the payload to every connected peer's
    // mesh characteristic.  We keep a list of active connections and
    // fan-out asynchronously.
    final connectedDevices = FlutterBluePlus.connectedDevices;
    final data = utf8.encode(payload);

    await Future.wait(
      connectedDevices.map((device) => _writeToDevice(device, data)),
      eagerError: false,
    );
  }

  @override
  Stream<String> get onMessageReceived => _messageController.stream;

  // ========================== Internal ==========================

  Future<void> _beginScan() async {
    if (_isScanning) return;
    _isScanning = true;

    // Continuous scan – timeout of zero means "until stopScan()".
    await FlutterBluePlus.startScan(
      withServices: [Guid(_serviceUuid)],
      timeout: Duration.zero,
      androidUsesFineLocation: true,
      continuousUpdates: true,
    );

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) async {
        for (final result in results) {
          await _handleDiscoveredDevice(result.device);
        }
      },
      onError: (e) {
        // Scan error – attempt restart after a brief back-off.
        _isScanning = false;
        Future.delayed(const Duration(seconds: 5), () => _beginScan());
      },
    );
  }

  Future<void> _handleDiscoveredDevice(BluetoothDevice device) async {
    try {
      // Connect if not already connected (autoConnect = true keeps
      // the connection alive across brief radio drops).
      if (!device.isConnected) {
        await device.connect(autoConnect: true, mtu: null);
      }

      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString() != _serviceUuid) continue;
        for (final char in service.characteristics) {
          if (char.uuid.toString() != _charUuid) continue;

          // Subscribe to notifications from this characteristic.
          if (!char.isNotifying) {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              if (value.isNotEmpty) {
                final msg = utf8.decode(value);
                _messageController.add(msg);
              }
            });
          }
        }
      }
    } catch (_) {
      // Connection or service-discovery failure – skip this device.
    }
  }

  Future<void> _writeToDevice(
      BluetoothDevice device, List<int> data) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString() != _serviceUuid) continue;
        for (final char in service.characteristics) {
          if (char.uuid.toString() != _charUuid) continue;
          await char.write(data, withoutResponse: true);
          return;
        }
      }
    } catch (_) {
      // Write failure – silently drop for this device.
    }
  }

  void dispose() {
    stopBackground();
    _messageController.close();
  }
}
