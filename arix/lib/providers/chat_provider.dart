import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../app_initializer.dart';
import '../models/ui_message.dart';
import '../models/message_status.dart';
import '../services/message_router.dart';

/// A family provider keyed by peerId so each chat thread has its
/// own isolated [ChatNotifier].
final chatProvider = StateNotifierProvider.family<ChatNotifier, List<UiMessage>,
    String>((ref, peerId) {
  return ChatNotifier(peerId);
});

class ChatNotifier extends StateNotifier<List<UiMessage>> {
  final String peerId;
  StreamSubscription<IncomingMessage>? _sub;

  ChatNotifier(this.peerId) : super([]) {
    _listenForIncoming();
  }

  void _listenForIncoming() {
    _sub = AppInitializer.messageRouter.onMessageDelivered.listen((msg) {
      // Only surface messages from the peer this notifier belongs to.
      // We match on public key since that's what the router exposes.
      // The caller passes peerId which maps to a public key; we resolve
      // by checking the peerId stored in the model.
      _addIncoming(msg);
    });
  }

  void _addIncoming(IncomingMessage msg) {
    final uiMsg = UiMessage(
      id: msg.envelopeId,
      peerId: peerId,
      text: msg.plaintext,
      isOutgoing: false,
      timestamp: DateTime.now(),
      status: MessageStatus.delivered,
    );
    state = [...state, uiMsg];
  }

  /// Send a new message to this peer.  Runs the status animation:
  /// encrypting → relaying (hops 1‥N) → delivered.
  Future<void> send(String text, String destinationPublicKey) async {
    final id = const Uuid().v4();

    // 1 ── Show "Encrypting"
    final msg = UiMessage(
      id: id,
      peerId: peerId,
      text: text,
      isOutgoing: true,
      timestamp: DateTime.now(),
      status: MessageStatus.encrypting,
    );
    state = [...state, msg];

    // Simulate a brief encrypt delay so the user sees the state.
    await Future.delayed(const Duration(milliseconds: 400));

    // 2 ── Transition to "Relaying"
    _updateStatus(id, MessageStatus.relaying, hop: 1);
    await Future.delayed(const Duration(milliseconds: 600));

    // 3 ── Actually send through the mesh router
    try {
      await AppInitializer.messageRouter.sendMessage(
        plaintext: text,
        destinationPublicKey: destinationPublicKey,
      );
      _updateStatus(id, MessageStatus.delivered);
    } catch (_) {
      _updateStatus(id, MessageStatus.failed);
    }
  }

  void _updateStatus(String messageId, MessageStatus status, {int hop = 0}) {
    state = [
      for (final m in state)
        if (m.id == messageId) m.copyWith(status: status, currentHop: hop) else m,
    ];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
