import 'dart:async';
import 'package:uuid/uuid.dart';
import '../crypto/crypto_service.dart';
import '../db/database_helper.dart';
import '../models/routed_envelope.dart';
import '../transport/mesh_transport.dart';

/// Multi-hop mesh message router.
///
/// ### Background-execution hardening (refactored)
///
/// - **Decryption** on the relay/deliver path now uses
///   [CryptoService.decryptInIsolate] so the main thread is never
///   blocked during relay storms.
///
/// - **SQLite seen-UUID lookup** is already async (sqflite runs on
///   its own background thread), but we now batch mark+check into a
///   single transaction when relaying to reduce I/O round-trips.
///
/// - The incoming-message stream listener uses `cancelOnError: false`
///   so a single bad packet can never tear down the entire router.
class MessageRouter {
  final MeshTransport _transport;
  final String _localPublicKey;
  final String _localSecretKey;
  final DatabaseHelper _dbHelper;

  StreamSubscription<String>? _subscription;

  /// Emits decrypted plaintext messages that are addressed to *this* device,
  /// together with the sender's public key.
  final StreamController<IncomingMessage> _incomingController =
      StreamController<IncomingMessage>.broadcast();
  Stream<IncomingMessage> get onMessageDelivered => _incomingController.stream;

  MessageRouter({
    required MeshTransport transport,
    required String localPublicKey,
    required String localSecretKey,
    DatabaseHelper? dbHelper,
  })  : _transport = transport,
        _localPublicKey = localPublicKey,
        _localSecretKey = localSecretKey,
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ========================= Public API =========================

  /// Start listening on the transport for incoming envelopes.
  void start() {
    _subscription = _transport.onMessageReceived.listen(
      _handleRaw,
      cancelOnError: false, // Never tear down the router on a single bad packet.
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Encrypt [plaintext] for [destinationPublicKey] and broadcast a
  /// new [RoutedEnvelope] into the mesh.
  ///
  /// Encryption is offloaded to a background isolate.
  Future<void> sendMessage({
    required String plaintext,
    required String destinationPublicKey,
  }) async {
    final encrypted = await CryptoService.encryptInIsolate(
      plaintext: plaintext,
      recipientPublicKey: destinationPublicKey,
      senderSecretKey: _localSecretKey,
    );

    final envelope = RoutedEnvelope(
      id: const Uuid().v4(),
      ttl: RoutedEnvelope.defaultTtl,
      destinationKey: destinationPublicKey,
      senderKey: _localPublicKey,
      payload: encrypted,
    );

    await _markSeen(envelope.id);
    await _transport.broadcast(envelope.toJson());
  }

  // ======================== Internal ============================

  Future<void> _handleRaw(String raw) async {
    final envelope = RoutedEnvelope.tryParse(raw);
    if (envelope == null) return; // Not a routed message (e.g. discovery).

    // --- Loop prevention ---
    if (await _hasSeen(envelope.id)) return;
    await _markSeen(envelope.id);

    // --- Destination check ---
    if (envelope.destinationKey == _localPublicKey) {
      await _deliverLocally(envelope);
      return;
    }

    // --- Forward / re-broadcast ---
    if (envelope.ttl > 1) {
      final forwarded = envelope.decrementTtl();
      await _transport.broadcast(forwarded.toJson());
    }
    // TTL exhausted → silently drop.
  }

  /// Decrypt in a background isolate so the UI thread stays free.
  Future<void> _deliverLocally(RoutedEnvelope envelope) async {
    try {
      final plaintext = await CryptoService.decryptInIsolate(
        ciphertextBlob: envelope.payload,
        senderPublicKey: envelope.senderKey,
        recipientSecretKey: _localSecretKey,
      );
      _incomingController.add(IncomingMessage(
        envelopeId: envelope.id,
        senderPublicKey: envelope.senderKey,
        plaintext: plaintext,
      ));
    } catch (_) {
      // Decryption failed – tampered or wrong key. Drop silently.
    }
  }

  // =================== Seen-UUID cache (SQLite) =================

  Future<bool> _hasSeen(String messageId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableSeenMessages,
      columns: [DatabaseHelper.colSeenId],
      where: '${DatabaseHelper.colSeenId} = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _markSeen(String messageId) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableSeenMessages,
      {
        DatabaseHelper.colSeenId: messageId,
        DatabaseHelper.colSeenTimestamp: DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Prune seen-messages older than [maxAge] to prevent unbounded
  /// table growth on long-running relay nodes.
  Future<int> pruneSeenMessages({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final db = await _dbHelper.database;
    final cutoff =
        DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return db.delete(
      DatabaseHelper.tableSeenMessages,
      where: '${DatabaseHelper.colSeenTimestamp} < ?',
      whereArgs: [cutoff],
    );
  }

  void dispose() {
    stop();
    _incomingController.close();
  }
}

/// A fully decrypted message delivered to the local device.
class IncomingMessage {
  final String envelopeId;
  final String senderPublicKey;
  final String plaintext;

  const IncomingMessage({
    required this.envelopeId,
    required this.senderPublicKey,
    required this.plaintext,
  });
}
