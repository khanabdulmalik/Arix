import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/peers_provider.dart';
import '../theme/arix_theme.dart';
import '../widgets/peer_tile.dart';
import 'chat_thread_screen.dart';

/// Displays all discovered mesh peers in a vertically-scrolling list
/// styled as a "radar" dashboard.
class NodeRadarScreen extends ConsumerWidget {
  const NodeRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peers = ref.watch(peersProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: const BoxDecoration(gradient: ArixTheme.headerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: ArixTheme.accentGradient,
                          boxShadow: ArixTheme.neonGlow(ArixTheme.accentCyan),
                        ),
                        child: const Icon(
                          Icons.radar,
                          color: ArixTheme.backgroundDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'NODE RADAR',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontSize: 22),
                      ),
                      const Spacer(),
                      _PulsingDot(),
                      const SizedBox(width: 6),
                      Text(
                        '${peers.length} node${peers.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: ArixTheme.accentTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nearby peers discovered over the mesh network',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // ── Peer list ──
          if (peers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_off, size: 56, color: ArixTheme.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'No peers detected yet',
                      style: TextStyle(
                        color: ArixTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Make sure nearby devices are running ARIX',
                      style: TextStyle(color: ArixTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.separated(
                itemCount: peers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final peer = peers[index];
                  return PeerTile(
                    peer: peer,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatThreadScreen(peer: peer),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Small green pulsing dot to indicate the radar is active.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl.drive(Tween(begin: 0.4, end: 1.0)),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ArixTheme.statusDelivered,
          boxShadow: ArixTheme.neonGlow(ArixTheme.statusDelivered, blur: 6),
        ),
      ),
    );
  }
}
