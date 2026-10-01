import 'package:flutter/material.dart';
import '../models/peer.dart';
import '../theme/arix_theme.dart';

/// A single row in the Node Radar list.
///
/// Shows a pulsing neon ring around the avatar, the peer name, a
/// truncated public-key fingerprint, and a "last seen" timestamp.
class PeerTile extends StatefulWidget {
  final Peer peer;
  final VoidCallback onTap;

  const PeerTile({super.key, required this.peer, required this.onTap});

  @override
  State<PeerTile> createState() => _PeerTileState();
}

class _PeerTileState extends State<PeerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fingerprint = widget.peer.publicKey.length > 12
        ? '${widget.peer.publicKey.substring(0, 6)}…${widget.peer.publicKey.substring(widget.peer.publicKey.length - 6)}'
        : widget.peer.publicKey;

    final lastSeen = DateTime.fromMillisecondsSinceEpoch(widget.peer.lastSeen);
    final ago = DateTime.now().difference(lastSeen);
    final agoLabel = ago.inSeconds < 60
        ? 'just now'
        : ago.inMinutes < 60
            ? '${ago.inMinutes}m ago'
            : '${ago.inHours}h ago';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: ArixTheme.cardRadius,
        splashColor: ArixTheme.accentCyan.withOpacity(0.08),
        highlightColor: ArixTheme.accentCyan.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ArixTheme.cardDark,
            borderRadius: ArixTheme.cardRadius,
            border: Border.all(color: ArixTheme.divider, width: 0.5),
          ),
          child: Row(
            children: [
              // ── Avatar with pulsing ring ──
              AnimatedBuilder(
                animation: _ring,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ArixTheme.accentGradient,
                      boxShadow: ArixTheme.neonGlow(
                        ArixTheme.accentCyan,
                        blur: 6 + (_ring.value * 8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.peer.name.isNotEmpty
                            ? widget.peer.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ArixTheme.backgroundDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),

              // ── Name & fingerprint ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.peer.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ArixTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '🔑 $fingerprint',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ArixTheme.textMuted,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Last seen ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ago.inMinutes < 5
                          ? ArixTheme.statusDelivered
                          : ArixTheme.textMuted,
                      boxShadow: ago.inMinutes < 5
                          ? ArixTheme.neonGlow(
                              ArixTheme.statusDelivered,
                              blur: 6,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    agoLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: ArixTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same as [AnimatedBuilder] – convenience alias.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  }) : super();

  @override
  Widget build(BuildContext context) => builder(context, child);
}
