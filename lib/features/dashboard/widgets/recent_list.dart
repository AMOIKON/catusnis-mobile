// lib/features/dashboard/widgets/recent_list.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/dashboard_stats.dart';

// ── Liste des déploiements récents ────────────────────────────────────────────
class RecentDeploymentsList extends StatelessWidget {
  final List<DeploymentItem> items;
  final bool isLoading;

  const RecentDeploymentsList({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Déploiements récents',
      icon: Icons.local_shipping_outlined,
      iconColor: AppTheme.success,
      isLoading: isLoading,
      emptyMsg: 'Aucun déploiement',
      itemCount: items.length,
      itemBuilder: (i) {
        final d = items[i];
        return _ListTileItem(
          icon: Icons.local_shipping_outlined,
          color: AppTheme.success,
          title: d.codeDep,
          subtitle: d.healthName ?? d.regionName ?? '—',
          trailing: d.dateRecept != null ? _formatDate(d.dateRecept!) : '',
        );
      },
    );
  }
}

// ── Liste des interventions récentes ─────────────────────────────────────────
class RecentInterventionsList extends StatelessWidget {
  final List<InterventionItem> items;
  final bool isLoading;

  const RecentInterventionsList({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Interventions récentes',
      icon: Icons.build_outlined,
      iconColor: AppTheme.warning,
      isLoading: isLoading,
      emptyMsg: 'Aucune intervention',
      itemCount: items.length,
      itemBuilder: (i) {
        final it = items[i];
        final color =
            it.typeInter == 'EN_LIGNE' ? AppTheme.info : AppTheme.warning;
        return _ListTileItem(
          icon: Icons.build_outlined,
          color: color,
          title: it.codeInter,
          subtitle: it.healthName ?? '—',
          trailing: it.typeInter ?? '',
        );
      },
    );
  }
}

// ── Liste des acquisitions récentes ──────────────────────────────────────────
class RecentAcquisitionsList extends StatelessWidget {
  final List<AcquisitionItem> items;
  final bool isLoading;

  const RecentAcquisitionsList({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Acquisitions récentes',
      icon: Icons.inventory_2_outlined,
      iconColor: AppTheme.primary,
      isLoading: isLoading,
      emptyMsg: 'Aucune acquisition',
      itemCount: items.length,
      itemBuilder: (i) {
        final a = items[i];
        final color = a.deployed ? AppTheme.success : AppTheme.primary;
        return _ListTileItem(
          icon: Icons.inventory_2_outlined,
          color: color,
          title: a.tag ?? a.serial ?? 'N/A',
          subtitle: a.typeName ?? '—',
          trailing: a.deployed ? 'Déployé' : 'Stock',
        );
      },
    );
  }
}

// ── Widget carte section ──────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;
  final String emptyMsg;
  final int itemCount;
  final Widget Function(int) itemBuilder;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isLoading,
    required this.emptyMsg,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            // ✅ Remplacer le Row de l'en-tête
            Row(children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                // ← ajouter Expanded
                child: Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Contenu
            if (isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (itemCount == 0)
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(emptyMsg,
                    style: const TextStyle(color: AppTheme.gray)),
              ))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => itemBuilder(i),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Widget ligne liste ────────────────────────────────────────────────────────
class _ListTileItem extends StatelessWidget {
  // ✅ Suppression du paramètre 'leading' dupliqué — un seul paramètre 'icon'
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;

  const _ListTileItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          )),
      subtitle: Text(subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.gray,
          )),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(trailing,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

// ── Helper date ───────────────────────────────────────────────────────────────
String _formatDate(String date) {
  try {
    final d = DateTime.parse(date);
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  } catch (_) {
    return date;
  }
}
