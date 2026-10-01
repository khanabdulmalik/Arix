import 'package:flutter/material.dart';
import '../models/message_status.dart';
import '../theme/arix_theme.dart';

/// Animated pill that shows the current delivery status of a message.
///
/// ```
///  🔒 Encrypting…
///  📡 Relaying (Hop 1)
///  ✓  Delivered
/// ```
class StatusIndicator extends StatefulWidget {
  final MessageStatus status;
  final int hop;

  const StatusIndicator({
    super.key,
    required this.status,
    this.hop = 0,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon, shouldPulse) = _resolve();

    Widget indicator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );

    if (shouldPulse) {
      indicator = FadeTransition(opacity: _pulse, child: indicator);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(widget.status),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: ArixTheme.chipRadius,
          border: Border.all(color: color.withOpacity(0.25), width: 0.5),
        ),
        child: indicator,
      ),
    );
  }

  (String, Color, IconData, bool) _resolve() {
    return switch (widget.status) {
      MessageStatus.encrypting => (
          'Encrypting…',
          ArixTheme.statusEncrypting,
          Icons.lock_outline,
          true,
        ),
      MessageStatus.relaying => (
          'Relaying (Hop ${widget.hop})',
          ArixTheme.statusRelaying,
          Icons.cell_tower,
          true,
        ),
      MessageStatus.delivered => (
          'Delivered',
          ArixTheme.statusDelivered,
          Icons.check_circle_outline,
          false,
        ),
      MessageStatus.failed => (
          'Failed',
          ArixTheme.statusFailed,
          Icons.error_outline,
          false,
        ),
    };
  }
}
