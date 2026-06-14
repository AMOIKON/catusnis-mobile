// lib/features/interventions/widgets/intervention_card.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/intervention_model.dart';

class InterventionCard extends StatelessWidget {
  final InterventionModel intervention;
  final VoidCallback? onTap;

  const InterventionCard({
    super.key,
    required this.intervention,
    this.onTap,
  });

  Color get _typeColor =>
      intervention.typeInter == 'EN_LIGNE' ? AppTheme.info : AppTheme.warning;
  IconData get _typeIcon => intervention.typeInter == 'EN_LIGNE'
      ? Icons.wifi
      : Icons.location_on_outlined;

  Color get _actionColor {
    switch (intervention.actionInter) {
      case 'MAINTENANCE_CURATIVE':
        return AppTheme.warning;
      case 'MAINTENANCE_PREVENTIVE':
        return AppTheme.success;
      case 'INSTALLATION':
        return AppTheme.primary;
      default:
        return AppTheme.gray;
    }
  }

  String get _actionLabel {
    switch (intervention.actionInter) {
      case 'MAINTENANCE_CURATIVE':
        return 'Curative';
      case 'MAINTENANCE_PREVENTIVE':
        return 'Préventive';
      case 'INSTALLATION':
        return 'Installation';
      default:
        return intervention.actionInter;
    }
  }

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
              // ── En-tête ──────────────────────────────────────
              Row(
                children: [
                  // Code
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon, size: 12, color: _typeColor),
                        const SizedBox(width: 4),
                        Text(intervention.codeInter,
                            style: TextStyle(
                                color: _typeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _actionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_actionLabel,
                        style: TextStyle(
                            color: _actionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  // Durée
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppTheme.gray),
                      const SizedBox(width: 3),
                      Text(
                        '${intervention.durationMinutes ?? 0} min',
                        style:
                            const TextStyle(fontSize: 12, color: AppTheme.gray),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Site de santé ─────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined,
                      size: 16, color: AppTheme.gray),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      intervention.healthName ?? 'Site inconnu',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.dark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Région / District ─────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.gray),
                  const SizedBox(width: 4),
                  Text(
                    '${intervention.districtName ?? ''} • ${intervention.regionName ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Équipement + Date ────────────────────────────
              Row(
                children: [
                  if (intervention.typeName != null) ...[
                    const Icon(Icons.devices_outlined,
                        size: 14, color: AppTheme.gray),
                    const SizedBox(width: 4),
                    Text(intervention.typeName!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.gray)),
                    const SizedBox(width: 12),
                  ],
                  if (intervention.dateInter != null) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.gray),
                    const SizedBox(width: 4),
                    Text(
                      intervention.dateInter!.substring(0, 10),
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.gray),
                    ),
                  ],
                ],
              ),

              // ── En attente maintenance ────────────────────────
              if (intervention.enAttenteMaintenance) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('En attente de maintenance',
                          style: TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
