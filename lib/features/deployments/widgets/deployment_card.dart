// lib/features/deployments/widgets/deployment_card.dart

import 'package:flutter/material.dart';
import '../models/deployment_model.dart';

// Couleurs directes — AppTheme non nécessaire ici
const _kSuccess = Color(0xFF388E3C);
const _kPrimary = Color(0xFF0D47A1);
const _kGray = Color(0xFF9E9E9E);
const _kDark = Color(0xFF212121);

class DeploymentCard extends StatelessWidget {
  final DeploymentModel deployment;
  final VoidCallback? onTap;

  const DeploymentCard({
    super.key,
    required this.deployment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(deployment.codeDep,
                      style: const TextStyle(
                          color: _kSuccess,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${deployment.items.length} équipement(s)',
                    style: const TextStyle(color: _kPrimary, fontSize: 11),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // Site de santé
              Row(children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 16, color: _kGray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deployment.healthName ?? 'Site inconnu',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _kDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 6),

              // Région / District
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: _kGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${deployment.districtName ?? ''} • ${deployment.regionName ?? ''}',
                    style: const TextStyle(fontSize: 12, color: _kGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 6),

              // Application + Date
              Row(children: [
                // ✅ app != null vérifié → utilise .  pas ?.
                if (deployment.app != null) ...[
                  const Icon(Icons.apps_outlined, size: 14, color: _kGray),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      deployment.app!.nomComplet,
                      style: const TextStyle(fontSize: 12, color: _kGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // ✅ dateReception != null vérifié → utilise .  pas ?.
                if (deployment.dateReception != null) ...[
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: _kGray),
                  const SizedBox(width: 4),
                  Text(
                    deployment.dateReception!.length >= 10
                        ? deployment.dateReception!.substring(0, 10)
                        : deployment.dateReception!,
                    style: const TextStyle(fontSize: 12, color: _kGray),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
