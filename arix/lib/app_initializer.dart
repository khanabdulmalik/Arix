import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto/key_manager.dart';
import 'db/database_helper.dart';
import 'db/peer_repository.dart';
import 'transport/transport_factory.dart';
import 'transport/mesh_transport.dart';
import 'services/peer_discovery_service.dart';
import 'services/message_router.dart';

/// Bootstraps all core subsystems in the correct order:
///
/// 1. Generate identity keypair (if first launch).
/// 2. Open the local SQLite database.
/// 3. Create the platform-appropriate [MeshTransport].
/// 4. Start [PeerDiscoveryService].
/// 5. Start [MessageRouter] (multi-hop encrypted relay).
///
/// Call [AppInitializer.initialize] once from `main()` before
/// `runApp()`.
class AppInitializer {
  static const _peerIdKey = 'arix_peer_id';

  static late MeshTransport transport;
  static late PeerRepository peerRepository;
  static late PeerDiscoveryService discoveryService;
  static late MessageRouter messageRouter;
  static late String localPeerId;
  static late String localPublicKey;

  static Future<void> initialize() async {
    final keyManager = KeyManager();
    final secureStorage = const FlutterSecureStorage();

    // --- 1. Identity keypair ---
    await keyManager.ensureKeyPairExists();
    localPublicKey = await keyManager.getPublicKey();

    // --- 2. Stable peer ID (persisted across launches) ---
    String? storedId = await secureStorage.read(key: _peerIdKey);
    if (storedId == null) {
      storedId = const Uuid().v4();
      await secureStorage.write(key: _peerIdKey, value: storedId);
    }
    localPeerId = storedId;

    // --- 3. Database ---
    peerRepository = PeerRepository();

    // --- 4. Transport (async – awaits socket/BLE readiness) ---
    transport = await TransportFactory.createTransport();

    // --- 5. Peer discovery ---
    discoveryService = PeerDiscoveryService(
      transport: transport,
      repository: peerRepository,
      localPeerId: localPeerId,
      localName: _deviceName(),
      localPublicKey: localPublicKey,
    );
    discoveryService.start();

    // --- 6. Multi-hop message router ---
    final localSecretKey = await keyManager.getSecretKey();
    messageRouter = MessageRouter(
      transport: transport,
      localPublicKey: localPublicKey,
      localSecretKey: localSecretKey,
    );
    messageRouter.start();
  }

  /// Best-effort human-readable device name.
  static String _deviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'arix-device';
    }
  }
}
