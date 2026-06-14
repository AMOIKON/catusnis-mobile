// lib/shared/widgets/wifi_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';

class WifiToggleButton extends StatelessWidget {
  const WifiToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final sync = context.watch<SyncService>();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showBottomSheet(context, connectivity, sync),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Icon(
                    connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                    color: connectivity.isOnline ? Colors.white : Colors.orange,
                    size: 24,
                  ),
                ),
                if (sync.pendingCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${sync.pendingCount > 9 ? '9+' : sync.pendingCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(
    BuildContext context,
    ConnectivityService connectivity,
    SyncService sync,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              // ── Statut ──────────────────────────────────────
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: connectivity.isOnline
                        ? Colors.green.withValues(alpha: 0.12) // ✅ corrigé
                        : Colors.orange.withValues(alpha: 0.12), // ✅ corrigé
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                    color: connectivity.isOnline ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectivity.isOnline
                          ? 'Connecté au réseau'
                          : 'Mode hors ligne',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: connectivity.isOnline
                              ? Colors.green
                              : Colors.orange),
                    ),
                    Text(
                      connectivity.isSimulatingOffline
                          ? 'Simulation hors ligne activée'
                          : connectivity.isOnline
                              ? 'Données synchronisées'
                              : 'Sync à la reconnexion',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              // ── File d'attente ───────────────────────────────
              if (sync.pendingCount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1), // ✅ corrigé
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            Colors.orange.withValues(alpha: 0.3)), // ✅ corrigé
                  ),
                  child: Row(children: [
                    const Icon(Icons.cloud_upload_outlined,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${sync.pendingCount} élément(s) en attente',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              // ── Sync manuelle ────────────────────────────────
              if (connectivity.isOnline && sync.pendingCount > 0) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: sync.isSyncing
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            sync.syncAll();
                          },
                    icon: sync.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync, color: Colors.white),
                    label: Text(
                      sync.isSyncing
                          ? 'Synchronisation...'
                          : 'Synchroniser maintenant',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // ── Toggle simulation ────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    connectivity.toggleSimulation();
                  },
                  icon: Icon(
                    connectivity.isSimulatingOffline
                        ? Icons.wifi
                        : Icons.wifi_off,
                  ),
                  label: Text(
                    connectivity.isSimulatingOffline
                        ? 'Désactiver mode hors ligne'
                        : 'Simuler mode hors ligne',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: connectivity.isSimulatingOffline
                        ? Colors.green
                        : Colors.orange,
                    side: BorderSide(
                      color: connectivity.isSimulatingOffline
                          ? Colors.green
                          : Colors.orange,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
