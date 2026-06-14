// lib/features/booklets/screens/booklet_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../models/booklet_model.dart';
import '../providers/booklet_provider.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0F4C81);
const _kGray = Color(0xFF607D8B);
const _kBg = Color(0xFFF0F4F8);

const _badgeColors = [
  Color(0xFF0F4C81),
  Color(0xFF2E7D32),
  Color(0xFFC27803),
  Color(0xFF7E3AF2),
  Color(0xFF0694A2),
  Color(0xFFE02424),
];
Color _colorForIdx(int i) => _badgeColors[i % _badgeColors.length];

String _badge(String name) {
  final w = name.trim().split(RegExp(r'\s+'));
  return (w.length >= 2
          ? '${w[0][0]}${w[1][0]}'
          : name.substring(0, name.length >= 2 ? 2 : 1))
      .toUpperCase();
}

// ── Couleur par statut ────────────────────────────────────────────────────────
Color _statusColor(String? s) {
  switch (s) {
    case 'Affecté':
      return const Color(0xFF2E7D32);
    case 'Réaffecté':
      return const Color(0xFF1565C0);
    case 'Retiré':
      return const Color(0xFFC81E1E);
    default:
      return _kGray;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class BookletScreen extends StatefulWidget {
  const BookletScreen({super.key});
  @override
  State<BookletScreen> createState() => _BookletScreenState();
}

class _BookletScreenState extends State<BookletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookletProvider>().charger(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookletProvider>();
    final grouped = prov.groupedByRegion;

    if (prov.hasError && prov.items.isEmpty) {
      return NetworkErrorWidget(onRetry: () => prov.charger(refresh: true));
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── KPI bar ────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _KpiPill('Total', prov.items.length, Colors.white)),
              Expanded(
                  child: _KpiPill('Affectés', prov.countByStatut('Affecté'),
                      const Color(0xFFBBF7D0))),
              Expanded(
                  child: _KpiPill('Réaff.', prov.countByStatut('Réaffecté'),
                      const Color(0xFFBAE6FD))),
              Expanded(
                  child: _KpiPill('Retirés', prov.countByStatut('Retiré'),
                      const Color(0xFFFCA5A5))),
              Expanded(
                  child: _KpiPill(
                      'Régions', grouped.length, const Color(0xFFFDE68A))),
            ],
          ),
        ),

        // ── Chips filtre statut ───────────────────────────────────────────
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _filterChip(context, prov, null, 'Tous', _kPrimary),
              ...prov.statuses.map((s) => _filterChip(
                    context,
                    prov,
                    s.statusName,
                    s.statusName,
                    _statusColor(s.statusName),
                  )),
            ],
          ),
        ),

        // ── Liste groupée par région ──────────────────────────────────────
        Expanded(
          child: prov.isLoading && prov.items.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : grouped.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: () => prov.charger(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 90),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          return _RegionRow(
                            regionName: entry.key,
                            items: entry.value,
                            colorIdx: index,
                            onTap: () => _showRegionDetail(
                                context, entry.key, entry.value, index),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }

  // ── Chip filtre ────────────────────────────────────────────────────────────
  Widget _filterChip(
    BuildContext context,
    BookletProvider prov,
    String? value,
    String label,
    Color color,
  ) {
    final sel = prov.filtreStatut == value;
    return GestureDetector(
      onTap: () => prov.setFiltreStatut(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: sel ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
              color: sel ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  // ── Détail région ──────────────────────────────────────────────────────────
  void _showRegionDetail(
      BuildContext context, String region, List<BookletModel> items, int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RegionDetailScreen(
          regionName: region,
          items: items,
          colorIdx: idx,
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.menu_book_outlined,
                color: _kPrimary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Aucun agent de santé trouvé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('La liste des agents de santés apparaîtront ici',
              style: TextStyle(color: _kGray)),
        ]),
      );
}

// ── Row région ────────────────────────────────────────────────────────────────
class _RegionRow extends StatelessWidget {
  final String regionName;
  final List<BookletModel> items;
  final int colorIdx;
  final VoidCallback onTap;

  const _RegionRow({
    required this.regionName,
    required this.items,
    required this.colorIdx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForIdx(colorIdx);
    final total = items.length;
    final affectes = items.where((b) => b.statusName == 'Affecté').length;
    final reaffectes = items.where((b) => b.statusName == 'Réaffecté').length;
    final retires = items.where((b) => b.statusName == 'Retiré').length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(_badge(regionName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(regionName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (affectes > 0)
                        _MiniTag('$affectes affectés', const Color(0xFF2E7D32)),
                      if (affectes > 0 && reaffectes > 0)
                        const SizedBox(width: 4),
                      if (reaffectes > 0)
                        _MiniTag(
                            '$reaffectes réaffectés', const Color(0xFF1565C0)),
                      if (retires > 0 && (affectes > 0 || reaffectes > 0))
                        const SizedBox(width: 4),
                      if (retires > 0)
                        _MiniTag('$retires retirés', const Color(0xFFC81E1E)),
                    ]),
                  ],
                ),
              ),
              Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ]),
            ]),
          ),
          // Barre de progression statuts
          if (total > 0)
            SizedBox(
              height: 3,
              child: Row(children: [
                if (affectes > 0)
                  Expanded(
                      flex: affectes,
                      child: Container(color: const Color(0xFF2E7D32))),
                if (reaffectes > 0)
                  Expanded(
                      flex: reaffectes,
                      child: Container(color: const Color(0xFF1565C0))),
                if (retires > 0)
                  Expanded(
                      flex: retires,
                      child: Container(color: const Color(0xFFC81E1E))),
                if (affectes + reaffectes + retires < total)
                  Expanded(
                    flex: total - affectes - reaffectes - retires,
                    child: Container(color: Colors.grey[200]),
                  ),
              ]),
            ),
          Divider(height: 1, color: Colors.grey[100]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN DÉTAIL RÉGION
// ═══════════════════════════════════════════════════════════════════════════════
class _RegionDetailScreen extends StatefulWidget {
  final String regionName;
  final List<BookletModel> items;
  final int colorIdx;

  const _RegionDetailScreen({
    required this.regionName,
    required this.items,
    required this.colorIdx,
  });

  @override
  State<_RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<_RegionDetailScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statutFilter;

  List<BookletModel> get _filtered => widget.items.where((b) {
        final q = _query.toLowerCase();
        final match = q.isEmpty ||
            b.fullName.toLowerCase().contains(q) ||
            (b.districtName?.toLowerCase().contains(q) ?? false) ||
            (b.postName?.toLowerCase().contains(q) ?? false) ||
            (b.contact?.toLowerCase().contains(q) ?? false);
        final statusOk = _statutFilter == null || b.statusName == _statutFilter;
        return match && statusOk;
      }).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final color = _colorForIdx(widget.colorIdx);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(_badge(widget.regionName),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.regionName,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${widget.items.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
      body: Column(children: [
        // Recherche
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher (nom, district, poste…)',
              hintStyle: const TextStyle(color: _kGray, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _kGray, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: _kGray,
                      onPressed: () => setState(() {
                        _query = '';
                        _searchCtrl.clear();
                      }),
                    )
                  : null,
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        // Filtres statut
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [null, 'Affecté', 'Réaffecté', 'Retiré']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _statutFilter = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statutFilter == s
                                  ? _kPrimary
                                  : _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              s ?? 'Tous',
                              style: TextStyle(
                                color: _statutFilter == s
                                    ? Colors.white
                                    : _kPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        // Compteur
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            Text('${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                style: const TextStyle(color: _kGray, fontSize: 12)),
          ]),
        ),
        const Divider(height: 1),

        // Liste
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('Aucun résultat',
                          style: TextStyle(color: _kGray)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (ctx, i) => _BookletTile(booklet: filtered[i]),
                ),
        ),
      ]),
    );
  }
}

// ── Tuile booklet ─────────────────────────────────────────────────────────────
class _BookletTile extends StatelessWidget {
  final BookletModel booklet;
  const _BookletTile({required this.booklet});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booklet.statusName);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Avatar initiales
        CircleAvatar(
          radius: 22,
          backgroundColor: _kPrimary.withValues(alpha: 0.12),
          child: Text(booklet.initials,
              style: const TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booklet.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF111827))),
              const SizedBox(height: 2),
              if (booklet.postName != null)
                Text(booklet.postName!,
                    style: const TextStyle(fontSize: 11, color: _kGray)),
              if (booklet.districtName != null)
                Text(booklet.districtName!,
                    style: const TextStyle(fontSize: 11, color: _kGray)),
              if (booklet.contact != null && booklet.contact!.isNotEmpty)
                Text('📞 ${booklet.contact}',
                    style: const TextStyle(fontSize: 10, color: _kGray)),
            ],
          ),
        ),
        // Badge statut
        if (booklet.statusName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(booklet.statusName!,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _KpiPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _KpiPill(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: color.withValues(alpha: 0.85), fontSize: 9)),
      ]);
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      );
}
