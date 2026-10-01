import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_initializer.dart';
import '../models/peer.dart';

/// Provides a reactive list of discovered peers.
///
/// Starts with whatever is already in the database, then appends
/// new peers as [PeerDiscoveryService.onNewPeerDiscovered] fires.
final peersProvider =
    StateNotifierProvider<PeersNotifier, List<Peer>>((ref) {
  return PeersNotifier();
});

class PeersNotifier extends StateNotifier<List<Peer>> {
  StreamSubscription<Peer>? _sub;

  PeersNotifier() : super([]) {
    _loadInitial();
    _sub = AppInitializer.discoveryService.onNewPeerDiscovered.listen((peer) {
      // Add to top of list if not already present.
      if (!state.any((p) => p.id == peer.id)) {
        state = [peer, ...state];
      }
    });
  }

  Future<void> _loadInitial() async {
    final peers = await AppInitializer.peerRepository.getAllPeers();
    state = peers;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
