import 'package:flutter/material.dart';
import '../models/ui_message.dart';
import '../theme/arix_theme.dart';
import 'status_indicator.dart';

/// A single chat bubble with an embedded [StatusIndicator].
///
/// Outgoing messages are right-aligned with a blue-tinted background.
/// Incoming messages are left-aligned with a surface-dark background.
class MessageBubble extends StatelessWidget {
  final UiMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isOut = message.isOutgoing;

    return Align(
      alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          left: isOut ? 64 : 12,
          right: isOut ? 12 : 64,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOut ? ArixTheme.bubbleOutgoing : ArixTheme.bubbleIncoming,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isOut ? 20 : 4),
            bottomRight: Radius.circular(isOut ? 4 : 20),
          ),
          border: Border.all(
            color: isOut
                ? ArixTheme.accentBlue.withOpacity(0.15)
                : ArixTheme.divider,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isOut ? ArixTheme.accentBlue : Colors.black)
                  .withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isOut ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 14.5,
                color: ArixTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: ArixTheme.textMuted,
                  ),
                ),
                if (isOut) ...[
                  const SizedBox(width: 8),
                  StatusIndicator(
                    status: message.status,
                    hop: message.currentHop,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
