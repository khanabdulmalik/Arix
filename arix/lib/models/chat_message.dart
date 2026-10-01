import '../db/database_helper.dart';

/// Data class representing a single chat message.
class ChatMessage {
  final String id;
  final String peerId;
  final String content;
  final bool isOutgoing;
  final int timestamp; // epoch milliseconds

  const ChatMessage({
    required this.id,
    required this.peerId,
    required this.content,
    required this.isOutgoing,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        DatabaseHelper.colMsgId: id,
        DatabaseHelper.colMsgPeerId: peerId,
        DatabaseHelper.colMsgContent: content,
        DatabaseHelper.colMsgIsOutgoing: isOutgoing ? 1 : 0,
        DatabaseHelper.colMsgTimestamp: timestamp,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map[DatabaseHelper.colMsgId] as String,
        peerId: map[DatabaseHelper.colMsgPeerId] as String,
        content: map[DatabaseHelper.colMsgContent] as String,
        isOutgoing: (map[DatabaseHelper.colMsgIsOutgoing] as int) == 1,
        timestamp: map[DatabaseHelper.colMsgTimestamp] as int,
      );
}
