import 'dart:io';
import 'mesh_transport.dart';
import 'ble_mesh_transport.dart';
import 'local_udp_transport.dart';

class TransportFactory {
  /// Creates the appropriate transport for the current platform.
  ///
  /// This is now **asynchronous** because [LocalUdpTransport] requires
  /// awaiting socket binding and [BleMeshTransport] requires starting
  /// background scanning.
  static Future<MeshTransport> createTransport() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final ble = BleMeshTransport();
      await ble.startBackground();
      return ble;
    } else {
      // Desktop — await socket readiness.
      return LocalUdpTransport.create();
    }
  }
}
