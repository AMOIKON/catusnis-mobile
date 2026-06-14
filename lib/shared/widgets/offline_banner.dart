// lib/shared/widgets/offline_banner.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityService>();

    return Column(children: [
      // ── Bannière hors ligne ──────────────────────────────────────────────
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: conn.isOffline ? 36 : 0,
        color: const Color(0xFFC81E1E),
        child: conn.isOffline
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 15),
                  const SizedBox(width: 8),
                  const Text(
                    'Hors ligne — Données depuis le cache local',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  // Indicateur simulation
                  if (conn.isSimulatingOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('SIMULÉ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              )
            : null,
      ),

      // ── Corps ─────────────────────────────────────────────────────────────
      Expanded(child: child),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge "Données du cache" — à afficher dans les écrans qui utilisent le cache
// ─────────────────────────────────────────────────────────────────────────────
class CacheBadge extends StatelessWidget {
  final bool fromCache;
  final DateTime? cachedAt;
  final VoidCallback? onRefresh;

  const CacheBadge({
    super.key,
    required this.fromCache,
    this.cachedAt,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!fromCache) return const SizedBox.shrink();

    final ago = cachedAt != null ? _formatAgo(cachedAt!) : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: Row(children: [
        const Icon(Icons.storage_outlined, color: Color(0xFF856404), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            ago.isNotEmpty
                ? 'Données du cache local ($ago)'
                : 'Données du cache local',
            style: const TextStyle(color: Color(0xFF856404), fontSize: 11),
          ),
        ),
        if (onRefresh != null)
          GestureDetector(
            onTap: onRefresh,
            child:
                const Icon(Icons.refresh, color: Color(0xFF856404), size: 16),
          ),
      ]),
    );
  }

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
