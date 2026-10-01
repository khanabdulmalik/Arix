import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/peer.dart';
import '../models/chat_message.dart';

/// Repository that encapsulates all database CRUD for peers and messages.
class PeerRepository {
  final DatabaseHelper _dbHelper;

  PeerRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ========================== Peers ==========================

  /// Insert or update a peer.  If the peer already exists (same id),
  /// only `last_seen` is bumped.
  Future<void> upsertPeer(Peer peer) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tablePeers,
      peer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve a single peer by its id, or `null` if not found.
  Future<Peer?> getPeerById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tablePeers,
      where: '${DatabaseHelper.colPeerId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Peer.fromMap(rows.first);
  }

  /// Return all known peers ordered by most-recently seen first.
  Future<List<Peer>> getAllPeers() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tablePeers,
      orderBy: '${DatabaseHelper.colPeerLastSeen} DESC',
    );
    return rows.map(Peer.fromMap).toList();
  }

  // ======================== Messages =========================

  /// Persist a chat message.
  Future<void> insertMessage(ChatMessage message) async {
    final db = await _dbHelper.database;
    await db.insert(DatabaseHelper.tableMessages, message.toMap());
  }

  /// Load the message history for a given peer, oldest-first.
  Future<List<ChatMessage>> getMessagesForPeer(
    String peerId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableMessages,
      where: '${DatabaseHelper.colMsgPeerId} = ?',
      whereArgs: [peerId],
      orderBy: '${DatabaseHelper.colMsgTimestamp} ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ChatMessage.fromMap).toList();
  }
}
