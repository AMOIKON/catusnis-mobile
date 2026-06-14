// lib/features/archives/widgets/archive_card.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/archive_model.dart';

class ArchiveCard extends StatelessWidget {
  final ArchiveModel archive;
  final VoidCallback? onTap;

  const ArchiveCard({
    super.key,
    required this.archive,
    this.onTap,
  });

  Color get _typeColor =>
      archive.isScanne ? AppTheme.primary : AppTheme.warning;

  String get _typeLabel => archive.isScanne ? 'Scanné' : 'Imprimé';

  Color get _catColor {
    switch (archive.categorie) {
      case 'INTERVENTION':
        return AppTheme.warning;
      case 'DEPLOIEMENT':
        return AppTheme.success;
      case 'ACQUISITION':
        return AppTheme.primary;
      case 'BOOKLET':
        return AppTheme.info;
      default:
        return AppTheme.gray;
    }
  }

  String get _catLabel {
    switch (archive.categorie) {
      case 'INTERVENTION':
        return 'Intervention';
      case 'DEPLOIEMENT':
        return 'Déploiement';
      case 'ACQUISITION':
        return 'Acquisition';
      case 'BOOKLET':
        return 'Cahier';
      case 'ACTIVE':
        return 'Actif';
      default:
        return 'Autre';
    }
  }

  IconData get _fileIcon {
    if (archive.isPdf) return Icons.picture_as_pdf_outlined;
    final mime = archive.mimeType ?? '';
    if (mime.contains('image')) return Icons.image_outlined;
    if (mime.contains('word')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
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
              // ── Icône fichier ────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_fileIcon, color: _typeColor, size: 26),
              ),
              const SizedBox(width: 12),

              // ── Infos ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(archive.titre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.dark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (archive.description != null &&
                        archive.description!.isNotEmpty)
                      Text(archive.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.gray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Badge type
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_typeLabel,
                              style: TextStyle(
                                  color: _typeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        // Badge catégorie
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_catLabel,
                              style: TextStyle(
                                  color: _catColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const Spacer(),
                        // Taille
                        if (archive.fileSizeLabel.isNotEmpty)
                          Text(archive.fileSizeLabel,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.gray)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.gray, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
