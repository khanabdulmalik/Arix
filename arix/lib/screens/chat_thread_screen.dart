import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/peer.dart';
import '../providers/chat_provider.dart';
import '../theme/arix_theme.dart';
import '../widgets/message_bubble.dart';

/// Full-screen chat thread for a single peer.
///
/// Reads from [chatProvider] keyed by [peer.id] and uses
/// [ChatNotifier.send] to dispatch outgoing messages through
/// the mesh router.
class ChatThreadScreen extends ConsumerStatefulWidget {
  final Peer peer;
  const ChatThreadScreen({super.key, required this.peer});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _canSend) setState(() => _canSend = hasText);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatProvider(widget.peer.id).notifier)
        .send(text, widget.peer.publicKey);

    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider(widget.peer.id));
    final fingerprint = widget.peer.publicKey.length > 12
        ? '${widget.peer.publicKey.substring(0, 6)}…${widget.peer.publicKey.substring(widget.peer.publicKey.length - 6)}'
        : widget.peer.publicKey;

    // Auto-scroll when new messages arrive.
    ref.listen(chatProvider(widget.peer.id), (_, __) => _scrollToBottom());

    return Scaffold(
      body: Column(
        children: [
          // ── Custom app bar ──
          _buildAppBar(context, fingerprint),

          // ── Messages ──
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => MessageBubble(message: messages[i]),
                  ),
          ),

          // ── Input bar ──
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String fingerprint) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: ArixTheme.surfaceDark,
        border: const Border(
          bottom: BorderSide(color: ArixTheme.divider, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: ArixTheme.accentCyan,
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ArixTheme.accentGradient,
              boxShadow: ArixTheme.neonGlow(ArixTheme.accentCyan, blur: 6),
            ),
            child: Center(
              child: Text(
                widget.peer.name.isNotEmpty
                    ? widget.peer.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ArixTheme.backgroundDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ArixTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 10, color: ArixTheme.accentTeal),
                    const SizedBox(width: 4),
                    Text(
                      'E2EE · $fingerprint',
                      style: const TextStyle(
                        fontSize: 10,
                        color: ArixTheme.textMuted,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Connection quality icon (decorative)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ArixTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cell_tower,
              size: 16,
              color: ArixTheme.accentCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArixTheme.surfaceLight.withOpacity(0.5),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 40, color: ArixTheme.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start a secure conversation',
            style: TextStyle(
              color: ArixTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Messages are end-to-end encrypted',
            style: TextStyle(color: ArixTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: ArixTheme.surfaceDark,
        border: const Border(
          top: BorderSide(color: ArixTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(
                  fontSize: 14, color: ArixTheme.textPrimary),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  _canSend ? ArixTheme.accentGradient : null,
              color: _canSend ? null : ArixTheme.surfaceLight,
              boxShadow: _canSend
                  ? ArixTheme.neonGlow(ArixTheme.accentCyan, blur: 8)
                  : null,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, size: 20),
              color:
                  _canSend ? ArixTheme.backgroundDark : ArixTheme.textMuted,
              onPressed: _canSend ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}
