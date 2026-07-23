// 📁 lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/server_wake_service.dart'; // ✅ AJOUT
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/deployments/providers/deployment_provider.dart';
import 'features/vehicules/providers/vehicule_provider.dart';
import 'features/fournitures/providers/fourniture_provider.dart';
import 'features/technician_sites/providers/technician_site_provider.dart';
import 'features/booklets/providers/booklet_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'shared/theme/app_theme.dart';
import 'features/notifications/providers/NotificationProvider.dart';
// Ajouter cet import avec les autres imports de providers
import 'features/structures/providers/structure_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    ConnectivityService? connectivity;
    SyncService? sync;

    try {
      connectivity = ConnectivityService();
      await connectivity.initialize();
    } catch (e) {
      debugPrint('ConnectivityService error: $e');
      connectivity = ConnectivityService();
    }

    try {
      sync = SyncService();
      sync.listenConnectivity();
    } catch (e) {
      debugPrint('SyncService error: $e');
      sync = SyncService();
    }

    runApp(CatusnisApp(connectivity: connectivity, sync: sync));
  } catch (e) {
    debugPrint('FATAL ERROR: $e');
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0D3380),
        body: Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      ),
    ));
  }
}

class CatusnisApp extends StatelessWidget {
  final ConnectivityService connectivity;
  final SyncService sync;

  const CatusnisApp({
    super.key,
    required this.connectivity,
    required this.sync,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Wake-up serveur — en premier pour que _AuthGate y ait accès ──────
        ChangeNotifierProvider(create: (_) => ServerWakeService()), // ✅ AJOUT

        // ── Core ──────────────────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: sync),

        // ── Déploiements ──────────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => DeploymentListProvider()),
        ChangeNotifierProvider(create: (_) => DeploymentFicheProvider()),
        ChangeNotifierProvider(create: (_) => DeploymentFormProvider()),

        // ── Véhicules ─────────────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => VehiculeProvider()),

        // ── Fournitures ───────────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => FournitureProvider()),

        // ── Périmètre géographique ────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => TechnicianSiteProvider()),

        // ── Booklets ──────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => BookletProvider()),

        // ── Notifications ───────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // ── Structures étatiques ──────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => StructureListProvider()),
      ],
      child: MaterialApp(
        title: 'CATUSNIS Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
        routes: {
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // ✅ 1. Réveiller le serveur d'abord
      final ok = await context.read<ServerWakeService>().wakeUp();

      // ✅ 2. Serveur prêt → initialiser l'auth
      if (ok && mounted) {
        context.read<AuthProvider>().initialize();
      }
    });

    // Durée minimale du splash (UX)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wake = context.watch<ServerWakeService>(); // ✅ AJOUT

    // Rester sur splash si : durée minimale non atteinte
    //                        OU serveur en cours de réveil
    //                        OU auth en cours de vérification
    if (!_splashDone || wake.isWaking || auth.status == AuthStatus.checking) {
      return const SplashScreen();
    }

    // Échec réseau → rester sur splash (bouton Réessayer visible)
    if (wake.hasFailed) return const SplashScreen();

    return switch (auth.status) {
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.checking => const SplashScreen(),
    };
  }
}
