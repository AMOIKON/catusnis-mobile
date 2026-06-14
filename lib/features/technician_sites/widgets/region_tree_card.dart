// lib/features/technician_sites/widgets/region_tree_card.dart

import 'package:flutter/material.dart';
import '../models/technician_site.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Carte Région — affiche ses districts et sites imbriqués
// ─────────────────────────────────────────────────────────────────────────────
class RegionTreeCard extends StatefulWidget {
  final RegionNode region;
  final bool canManage;
  final void Function(int id) onDelete;
  final VoidCallback onEdit;

  const RegionTreeCard({
    super.key,
    required this.region,
    required this.canManage,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<RegionTreeCard> createState() => _RegionTreeCardState();
}

class _RegionTreeCardState extends State<RegionTreeCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final region = widget.region;
    final totalSites = region.districts.fold<int>(
      0,
      (sum, d) => sum + d.sites.length,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── En-tête Région ────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                ),
              ),
              child: Row(children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF1D4ED8),
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Icon(Icons.public, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    region.regionName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                      fontSize: 14,
                    ),
                  ),
                ),
                // Badges compteurs
                _CountBadge(
                  count: region.districts.length,
                  label: 'dist.',
                  color: Colors.blue.shade100,
                  textColor: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                _CountBadge(
                  count: totalSites,
                  label: 'sites',
                  color: Colors.green.shade100,
                  textColor: Colors.green.shade700,
                ),
                if (widget.canManage) ...[
                  const SizedBox(width: 6),
                  _ActionButtons(
                    onEdit: widget.onEdit,
                    onDelete: region.assignment != null
                        ? () => widget.onDelete(region.assignment!.id)
                        : null,
                  ),
                ],
              ]),
            ),
          ),

          // ── Districts ─────────────────────────────────────────────────────
          if (_expanded)
            ...region.districts.map(
              (dist) => _DistrictTile(
                district: dist,
                canManage: widget.canManage,
                onDelete: widget.onDelete,
                onEdit: widget.onEdit,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ligne District
// ─────────────────────────────────────────────────────────────────────────────
class _DistrictTile extends StatefulWidget {
  final DistrictNode district;
  final bool canManage;
  final void Function(int) onDelete;
  final VoidCallback onEdit;

  const _DistrictTile({
    required this.district,
    required this.canManage,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_DistrictTile> createState() => _DistrictTileState();
}

class _DistrictTileState extends State<_DistrictTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final dist = widget.district;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(color: Colors.blue.shade200, width: 3),
        ),
      ),
      child: Column(
        children: [
          // ── En-tête District ────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
              child: Row(children: [
                Text('└─ ', style: TextStyle(color: Colors.grey.shade400)),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue.shade400,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.location_city,
                    color: Color(0xFF0369A1), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dist.districtName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0369A1),
                      fontSize: 13,
                    ),
                  ),
                ),
                _CountBadge(
                  count: dist.sites.length,
                  label: 'sites',
                  color: Colors.green.shade100,
                  textColor: Colors.green.shade700,
                ),
                if (widget.canManage) ...[
                  const SizedBox(width: 6),
                  _ActionButtons(
                    onEdit: widget.onEdit,
                    onDelete: dist.assignment != null
                        ? () => widget.onDelete(dist.assignment!.id)
                        : null,
                    compact: true,
                  ),
                ],
              ]),
            ),
          ),

          // ── Sites ─────────────────────────────────────────────────────
          if (_expanded)
            ...dist.sites.map((site) => _SiteTile(
                  site: site,
                  canManage: widget.canManage,
                  onDelete: widget.onDelete,
                  onEdit: widget.onEdit,
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ligne Site
// ─────────────────────────────────────────────────────────────────────────────
class _SiteTile extends StatelessWidget {
  final TechnicianSite site;
  final bool canManage;
  final void Function(int) onDelete;
  final VoidCallback onEdit;

  const _SiteTile({
    required this.site,
    required this.canManage,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          left: BorderSide(color: Colors.green.shade200, width: 3),
        ),
      ),
      child: Row(children: [
        Text('└─ ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        const Icon(Icons.local_hospital, color: Color(0xFF166534), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            site.healthName ?? '—',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
              fontSize: 12,
            ),
          ),
        ),
        if (site.createdAt != null)
          Text(
            site.createdAt!.length > 10
                ? site.createdAt!.substring(0, 10)
                : site.createdAt!,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        if (canManage) ...[
          const SizedBox(width: 6),
          _ActionButtons(
            onEdit: onEdit,
            onDelete: () => onDelete(site.id),
            compact: true,
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges et boutons réutilisables
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color textColor;

  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count $label',
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  const _ActionButtons({
    required this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 32.0;
    final iconSize = compact ? 14.0 : 16.0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.add_circle_outline,
              size: iconSize, color: Colors.blue.shade600),
          tooltip: 'Ajouter',
          onPressed: onEdit,
        ),
      ),
      if (onDelete != null)
        SizedBox(
          width: size,
          height: size,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.delete_outline,
                size: iconSize, color: Colors.red.shade400),
            tooltip: 'Retirer',
            onPressed: onDelete,
          ),
        ),
    ]);
  }
}
