import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../transport/mesh_transport.dart';
import '../db/peer_repository.dart';
import '../models/peer.dart';

/// Listens on [MeshTransport.onMessageReceived] for discovery
/// announcements from other peers and persists them to the local
/// database together with their public key.
///
/// ### Wire format (JSON)
/// Every device periodically broadcasts a discovery announcement:
/// ```json
/// {
///   "type": "discovery",
///   "peerId": "<uuid>",
///   "name": "<device name>",
///   "publicKey": "<base64 X25519 public key>"
/// }
/// ```
class PeerDiscoveryService {
  final MeshTransport _transport;
  final PeerRepository _repository;
  final String _localPeerId;
  final String _localName;
  final String _localPublicKey;

  StreamSubscription<String>? _subscription;

  /// Stream that emits a [Peer] every time a *new* (previously unknown)
  /// peer is persisted.
  final StreamController<Peer> _newPeerController =
      StreamController<Peer>.broadcast();
  Stream<Peer> get onNewPeerDiscovered => _newPeerController.stream;

  PeerDiscoveryService({
    required MeshTransport transport,
    required PeerRepository repository,
    required String localPeerId,
    required String localName,
    required String localPublicKey,
  })  : _transport = transport,
        _repository = repository,
        _localPeerId = localPeerId,
        _localName = localName,
        _localPublicKey = localPublicKey;

  /// Start listening for incoming discovery messages and periodically
  /// broadcast our own presence.
  void start() {
    _subscription = _transport.onMessageReceived.listen(_handleMessage);
    _broadcastPresence();
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Broadcast this device's discovery announcement.
  Future<void> _broadcastPresence() async {
    final announcement = jsonEncode({
      'type': 'discovery',
      'peerId': _localPeerId,
      'name': _localName,
      'publicKey': _localPublicKey,
    });
    await _transport.broadcast(announcement);
  }

  Future<void> _handleMessage(String raw) async {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != 'discovery') return;

      final peerId = map['peerId'] as String;
      if (peerId == _localPeerId) return; // Ignore our own broadcast.

      final now = DateTime.now().millisecondsSinceEpoch;

      final existingPeer = await _repository.getPeerById(peerId);
      final peer = Peer(
        id: peerId,
        name: map['name'] as String,
        publicKey: map['publicKey'] as String,
        firstSeen: existingPeer?.firstSeen ?? now,
        lastSeen: now,
      );

      await _repository.upsertPeer(peer);

      if (existingPeer == null) {
        _newPeerController.add(peer);
      }
    } catch (_) {
      // Not a valid discovery packet – ignore.
    }
  }

  void dispose() {
    stop();
    _newPeerController.close();
  }
}
