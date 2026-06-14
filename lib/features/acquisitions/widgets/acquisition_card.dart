// lib/features/acquisitions/widgets/acquisition_card.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/acquisition_model.dart';

class AcquisitionCard extends StatelessWidget {
  final AcquisitionModel acquisition;
  final VoidCallback? onTap;

  const AcquisitionCard({
    super.key,
    required this.acquisition,
    this.onTap,
  });

  Color get _statusColor {
    switch (acquisition.status) {
      case 'DISPONIBLE':
        return AppTheme.success;
      case 'DEPLOYE':
        return AppTheme.primary;
      case 'EN_PANNE':
        return Colors.red;
      case 'MAINTENANCE':
        return AppTheme.warning;
      default:
        return AppTheme.gray;
    }
  }

  String get _statusLabel {
    switch (acquisition.status) {
      case 'DISPONIBLE':
        return 'Disponible';
      case 'DEPLOYE':
        return 'Déployé';
      case 'EN_PANNE':
        return 'En panne';
      case 'MAINTENANCE':
        return 'Maintenance';
      default:
        return acquisition.status;
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
          child: Row(
            children: [
              // ── Icône équipement ──────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.devices_outlined, color: _statusColor, size: 26),
              ),
              const SizedBox(width: 12),

              // ── Infos ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Text(acquisition.tag,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.dark)),
                    const SizedBox(height: 4),
                    // Type
                    if (acquisition.typeName != null)
                      Text(acquisition.typeName!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.gray)),
                    const SizedBox(height: 4),
                    // Partenaire + Date
                    Row(
                      children: [
                        if (acquisition.partnerName != null) ...[
                          const Icon(Icons.business_outlined,
                              size: 12, color: AppTheme.gray),
                          const SizedBox(width: 3),
                          Text(acquisition.partnerName!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.gray)),
                          const SizedBox(width: 10),
                        ],
                        if (acquisition.dateAcq != null) ...[
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppTheme.gray),
                          const SizedBox(width: 3),
                          Text(
                            acquisition.dateAcq!.substring(0, 10),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.gray),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Badge statut ──────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (acquisition.deployed) ...[
                    const SizedBox(height: 6),
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: AppTheme.primary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
