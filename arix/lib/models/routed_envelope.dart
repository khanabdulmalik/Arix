import 'dart:convert';

/// Wire-format envelope that wraps every routed mesh message.
///
/// ```json
/// {
///   "type": "mesh_message",
///   "id": "a1b2c3d4-...",
///   "ttl": 5,
///   "destinationKey": "<base64 X25519 public key>",
///   "senderKey": "<base64 X25519 public key>",
///   "payload": "<base64 encrypted blob>"
/// }
/// ```
class RoutedEnvelope {
  static const String messageType = 'mesh_message';
  static const int defaultTtl = 5;

  final String id;
  final int ttl;
  final String destinationKey; // Base64 public key of intended recipient
  final String senderKey;      // Base64 public key of original sender
  final String payload;        // Base64 encrypted ciphertext blob

  const RoutedEnvelope({
    required this.id,
    required this.ttl,
    required this.destinationKey,
    required this.senderKey,
    required this.payload,
  });

  /// Create a copy with a decremented TTL for re-broadcast.
  RoutedEnvelope decrementTtl() => RoutedEnvelope(
        id: id,
        ttl: ttl - 1,
        destinationKey: destinationKey,
        senderKey: senderKey,
        payload: payload,
      );

  /// Serialize to a JSON string suitable for [MeshTransport.broadcast].
  String toJson() => jsonEncode({
        'type': messageType,
        'id': id,
        'ttl': ttl,
        'destinationKey': destinationKey,
        'senderKey': senderKey,
        'payload': payload,
      });

  /// Try to parse a raw JSON string.  Returns `null` if the string
  /// is not a valid mesh_message envelope.
  static RoutedEnvelope? tryParse(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != messageType) return null;
      return RoutedEnvelope(
        id: map['id'] as String,
        ttl: map['ttl'] as int,
        destinationKey: map['destinationKey'] as String,
        senderKey: map['senderKey'] as String,
        payload: map['payload'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
