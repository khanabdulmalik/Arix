import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'mesh_transport.dart';

/// Desktop UDP multicast transport for testing the mesh without
/// physical BLE hardware.
///
/// ### Background-execution notes (refactored)
///
/// - Socket binding is now **fully awaited** before any listener
///   is attached — the original fire-and-forget `_initSocket()` in the
///   constructor was a race condition (messages arriving before the
///   socket was ready were silently lost).
///
/// - Exposes a static [create] factory that returns a `Future` so the
///   caller can `await` readiness.
///
/// - Uses `reusePort: true` so multiple desktop windows can bind to
///   the same port simultaneously for multi-instance testing.
class LocalUdpTransport implements MeshTransport {
  static const int _port = 5555;
  static const String _multicastAddress = '224.0.2.200';

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final RawDatagramSocket _socket;

  /// Private constructor — use [create] instead.
  LocalUdpTransport._(this._socket) {
    _socket.joinMulticast(InternetAddress(_multicastAddress));
    _socket.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket.receive();
          if (datagram != null) {
            _messageController.add(utf8.decode(datagram.data));
          }
        }
      },
      onError: (e) {
        // Log but don't crash – the socket will still accept writes.
        print('[LocalUdpTransport] Socket error: $e');
      },
    );
  }

  /// Asynchronous factory that ensures the socket is fully bound before
  /// returning.
  static Future<LocalUdpTransport> create() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _port,
      reusePort: true,
    );
    return LocalUdpTransport._(socket);
  }

  @override
  Future<void> broadcast(String payload) async {
    final data = utf8.encode(payload);
    _socket.send(data, InternetAddress(_multicastAddress), _port);
  }

  @override
  Stream<String> get onMessageReceived => _messageController.stream;

  void dispose() {
    _socket.close();
    _messageController.close();
  }
}
