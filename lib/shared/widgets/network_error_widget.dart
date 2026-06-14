// lib/shared/widgets/network_error_widget.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NetworkErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const NetworkErrorWidget({
    super.key,
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_outlined,
                  color: Colors.red, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Erreur de connexion',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark)),
            const SizedBox(height: 8),
            Text(
              message ?? 'Vérifiez votre connexion réseau\net réessayez.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.gray),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
