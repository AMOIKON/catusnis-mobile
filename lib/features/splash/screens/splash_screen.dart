// 📁 lib/features/splash/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/server_wake_service.dart';
import '../../../shared/widgets/catusnis_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wake = context.watch<ServerWakeService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D3380),
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo

              Image.asset(
                'assets/icons/app_icon.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),

              // Nom coloré
              FittedBox(
                fit: BoxFit.scaleDown,
                child: const CatusnisText(fontSize: 36),
              ),
              const SizedBox(height: 8),
              Text(
                'Centre d\'assistance technique aux utilisateurs\ndu système national d\'information sanitaire',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Statut connexion serveur
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(children: [
                  if (wake.isWaking) ...[
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (wake.isOnline) ...[
                    const Icon(Icons.check_circle_outline,
                        color: Colors.greenAccent, size: 22),
                    const SizedBox(height: 10),
                  ] else if (wake.hasFailed) ...[
                    const Icon(Icons.cloud_off_outlined,
                        color: Colors.redAccent, size: 22),
                    const SizedBox(height: 10),
                  ] else ...[
                    const SizedBox(height: 32),
                  ],
                  Text(
                    wake.message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (wake.hasFailed) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.read<ServerWakeService>().wakeUp(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ]),
              ),

              const SizedBox(height: 48),

              Text(
                'v1.0.0 · Côte d\'Ivoire',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
