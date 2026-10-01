import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton wrapper around the local SQLite database.
/// Creates three tables:
///   • `peers`         – discovered BLE peers and their public keys
///   • `messages`      – chat message history
///   • `seen_messages` – UUID cache for mesh routing loop prevention
class DatabaseHelper {
  static const _databaseName = 'arix.db';
  static const _databaseVersion = 1;

  // --------------- Tables ---------------
  static const tablePeers = 'peers';
  static const tableMessages = 'messages';
  static const tableSeenMessages = 'seen_messages';

  // --------------- Peer columns ---------------
  static const colPeerId = 'id';           // TEXT PRIMARY KEY (UUID)
  static const colPeerName = 'name';       // TEXT
  static const colPeerPublicKey = 'public_key'; // TEXT (Base64)
  static const colPeerFirstSeen = 'first_seen'; // INTEGER (epoch ms)
  static const colPeerLastSeen = 'last_seen';   // INTEGER (epoch ms)

  // --------------- Message columns ---------------
  static const colMsgId = 'id';            // TEXT PRIMARY KEY (UUID)
  static const colMsgPeerId = 'peer_id';   // TEXT FK → peers.id
  static const colMsgContent = 'content';  // TEXT (encrypted blob or plaintext)
  static const colMsgIsOutgoing = 'is_outgoing'; // INTEGER (0/1)
  static const colMsgTimestamp = 'timestamp';     // INTEGER (epoch ms)

  // --------------- Seen-message columns ---------------
  static const colSeenId = 'message_id';        // TEXT PRIMARY KEY (envelope UUID)
  static const colSeenTimestamp = 'seen_at';     // INTEGER (epoch ms)

  // --------------- Singleton ---------------
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePeers (
        $colPeerId      TEXT PRIMARY KEY,
        $colPeerName    TEXT NOT NULL,
        $colPeerPublicKey TEXT NOT NULL,
        $colPeerFirstSeen INTEGER NOT NULL,
        $colPeerLastSeen  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMessages (
        $colMsgId        TEXT PRIMARY KEY,
        $colMsgPeerId    TEXT NOT NULL,
        $colMsgContent   TEXT NOT NULL,
        $colMsgIsOutgoing INTEGER NOT NULL,
        $colMsgTimestamp  INTEGER NOT NULL,
        FOREIGN KEY ($colMsgPeerId) REFERENCES $tablePeers($colPeerId)
      )
    ''');

    // Index for fast history queries per peer.
    await db.execute('''
      CREATE INDEX idx_messages_peer
        ON $tableMessages ($colMsgPeerId, $colMsgTimestamp)
    ''');

    // Seen-message UUID cache for mesh routing loop prevention.
    await db.execute('''
      CREATE TABLE $tableSeenMessages (
        $colSeenId        TEXT PRIMARY KEY,
        $colSeenTimestamp  INTEGER NOT NULL
      )
    ''');
  }
}
