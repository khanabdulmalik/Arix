import 'message_status.dart';

/// UI-facing chat message with mutable delivery status.
class UiMessage {
  final String id;
  final String peerId;
  final String text;
  final bool isOutgoing;
  final DateTime timestamp;
  MessageStatus status;
  int currentHop;

  UiMessage({
    required this.id,
    required this.peerId,
    required this.text,
    required this.isOutgoing,
    required this.timestamp,
    this.status = MessageStatus.encrypting,
    this.currentHop = 0,
  });

  UiMessage copyWith({
    MessageStatus? status,
    int? currentHop,
  }) =>
      UiMessage(
        id: id,
        peerId: peerId,
        text: text,
        isOutgoing: isOutgoing,
        timestamp: timestamp,
        status: status ?? this.status,
        currentHop: currentHop ?? this.currentHop,
      );
}
