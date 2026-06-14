// lib/features/dashboard/widgets/stat_card.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),

            // Valeur
            isLoading
                ? SizedBox(
                    height: 32,
                    width: 60,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(4),
                      color: color,
                    ),
                  )
                : Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            const SizedBox(height: 4),

            // Label
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
