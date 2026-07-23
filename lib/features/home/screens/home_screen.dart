// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/catusnis_logo.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/NotificationBadge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../acquisitions/screens/acquisition_screen.dart';
import '../../deployments/screens/deployment_list_screen.dart';
import '../../interventions/screens/intervention_screen.dart';
import '../../archives/screens/archive_screen.dart';
import '../../vehicules/screens/vehicule_screen.dart';
import '../../fournitures/screens/fourniture_screen.dart';
import '../../technician_sites/screens/technician_site_screen.dart';
import '../../booklets/screens/booklet_screen.dart';
import '../../structures/screens/structure_list_screen.dart'; // ✅ AJOUT
import '../../notifications/providers/NotificationProvider.dart';
import '../../notifications/screens/NotificationScreen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum centralisé — partagé avec AppDrawer
// ─────────────────────────────────────────────────────────────────────────────
enum AppRoute {
  dashboard,
  acquisitions,
  deployments,
  interventions,
  archives,
  vehicules,
  fournitures,
  technicianSites,
  booklets,
  structures, // ✅ AJOUT
  notifications,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppRoute _currentRoute = AppRoute.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().initialize(user.id);
      }
    });
  }

  String _getTitle() {
    switch (_currentRoute) {
      case AppRoute.dashboard:
        return 'CATUSNIS';
      case AppRoute.acquisitions:
        return 'Acquisitions';
      case AppRoute.deployments:
        return 'Déploiements';
      case AppRoute.interventions:
        return 'Interventions';
      case AppRoute.archives:
        return 'Archives';
      case AppRoute.vehicules:
        return 'Parc logistique';
      case AppRoute.fournitures:
        return 'Fournitures & Mobilier';
      case AppRoute.technicianSites:
        return 'Sites attribués';
      case AppRoute.booklets:
        return 'Booklets';
      case AppRoute.structures: // ✅ AJOUT
        return 'Structures étatiques';
      case AppRoute.notifications:
        return 'Notifications';
    }
  }

  Widget _buildBody() {
    switch (_currentRoute) {
      case AppRoute.dashboard:
        return const DashboardScreen();
      case AppRoute.acquisitions:
        return AcquisitionScreen();
      case AppRoute.deployments:
        return const DeploymentListScreen();
      case AppRoute.interventions:
        return const InterventionScreen();
      case AppRoute.archives:
        return const ArchiveScreen();
      case AppRoute.vehicules:
        return VehiculeScreen();
      case AppRoute.fournitures:
        return FournitureScreen();
      case AppRoute.technicianSites:
        return const TechnicianSiteScreen();
      case AppRoute.booklets:
        return const BookletScreen();
      case AppRoute.structures: // ✅ AJOUT
        return const StructureListScreen();
      case AppRoute.notifications:
        return const NotificationScreen();
    }
  }

  Color get _appBarColor {
    switch (_currentRoute) {
      case AppRoute.vehicules:
        return const Color(0xFF2E7D32);
      case AppRoute.fournitures:
        return const Color(0xFF1565C0);
      case AppRoute.technicianSites:
        return const Color(0xFF0F4C81);
      case AppRoute.booklets:
        return const Color(0xFF0F4C81);
      case AppRoute.structures: // ✅ AJOUT
        return const Color(0xFF0F4C81);
      case AppRoute.notifications:
        return const Color(0xFFC81E1E);
      default:
        return const Color(0xFF0D3380);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/catusnis_animation.gif',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const CatusnisLogo(size: 32),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _currentRoute == AppRoute.dashboard
                    ? const _DashboardTitle(key: ValueKey('dash'))
                    : _ModuleTitle(
                        key: ValueKey(_currentRoute),
                        title: _getTitle(),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            _WifiButton(onTap: () => _showWifiSheet(context)),
          ]),
        ),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      drawer: AppDrawer(
        currentRoute: _currentRoute,
        onRouteSelected: (route) => setState(() => _currentRoute = route),
      ),
      body: OfflineBanner(child: _buildBody()),
    );
  }

  void _showWifiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _WifiSheet(),
    );
  }

  void _confirmLogout(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              context.read<NotificationProvider>().reset();
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Titre Dashboard ───────────────────────────────────────────────────────────
class _DashboardTitle extends StatelessWidget {
  const _DashboardTitle({super.key});
  @override
  Widget build(BuildContext context) => const CatusnisText(fontSize: 15);
}

// ── Titre Module ──────────────────────────────────────────────────────────────
class _ModuleTitle extends StatelessWidget {
  final String title;
  const _ModuleTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1)),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
}

// ── Wifi Button ───────────────────────────────────────────────────────────────
class _WifiButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WifiButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi, color: Color(0xFFFF6F00), size: 14),
            SizedBox(width: 3),
            Text('Réseau',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}

// ── Wifi Sheet ────────────────────────────────────────────────────────────────
class _WifiSheet extends StatefulWidget {
  const _WifiSheet();
  @override
  State<_WifiSheet> createState() => _WifiSheetState();
}

class _WifiSheetState extends State<_WifiSheet> {
  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final sync = context.watch<SyncService>();
    final isOnline = connectivity.isOnline;
    final isSim = connectivity.isSimulatingOffline;
    final pending = sync.pendingCount;
    final syncing = sync.isSyncing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        const Row(children: [
          Icon(Icons.wifi, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('État du réseau',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isOnline ? Colors.green : Colors.orange)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isOnline ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isOnline ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.orange,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isOnline ? '🟢  Connecté' : '🔴  Hors ligne',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isOnline ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSim
                    ? '⚠️ Simulation active'
                    : isOnline
                        ? 'Données synchronisées'
                        : 'Sync à la reconnexion',
                style: TextStyle(
                  color: isSim ? Colors.orange : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ]),
          ]),
        ),
        if (pending > 0) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.cloud_upload_outlined,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                '$pending élément(s) en attente',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        if (isOnline && pending > 0) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: syncing
                  ? null
                  : () {
                      Navigator.pop(context);
                      sync.syncAll();
                    },
              icon: syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, color: Colors.white),
              label: Text(
                syncing ? 'Synchronisation...' : 'Synchroniser maintenant',
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => connectivity.toggleSimulation(),
            icon:
                Icon(isSim ? Icons.wifi : Icons.wifi_off, color: Colors.white),
            label: Text(
              isSim
                  ? '✅  Réactiver le mode en ligne'
                  : '🔴  Simuler le mode hors ligne',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSim ? Colors.green : Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
        ),
      ]),
    );
  }
}
