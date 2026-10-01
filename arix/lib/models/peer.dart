import '../db/database_helper.dart';

/// Data class representing a discovered peer.
class Peer {
  final String id;
  final String name;
  final String publicKey; // Base64-encoded X25519 public key
  final int firstSeen;    // epoch milliseconds
  final int lastSeen;     // epoch milliseconds

  const Peer({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.firstSeen,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() => {
        DatabaseHelper.colPeerId: id,
        DatabaseHelper.colPeerName: name,
        DatabaseHelper.colPeerPublicKey: publicKey,
        DatabaseHelper.colPeerFirstSeen: firstSeen,
        DatabaseHelper.colPeerLastSeen: lastSeen,
      };

  factory Peer.fromMap(Map<String, dynamic> map) => Peer(
        id: map[DatabaseHelper.colPeerId] as String,
        name: map[DatabaseHelper.colPeerName] as String,
        publicKey: map[DatabaseHelper.colPeerPublicKey] as String,
        firstSeen: map[DatabaseHelper.colPeerFirstSeen] as int,
        lastSeen: map[DatabaseHelper.colPeerLastSeen] as int,
      );
}
