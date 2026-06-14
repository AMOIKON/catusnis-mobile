// lib/features/deployments/screens/deployment_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/deployment_model.dart';
import '../providers/deployment_provider.dart';
import 'deployment_fiche_screen.dart';
import 'deployment_form_screen.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2E7D52);
const _kBlue = Color(0xFF1565C0);
const _kRed = Color(0xFFC81E1E);
const _kGray = Color(0xFF607D8B);
const _kBrown = Color(0xFF795548);
const _kBg = Color(0xFFF4FAF6);

const _badgeColors = [
  Color(0xFF2E7D52),
  Color(0xFF1565C0),
  Color(0xFFC27803),
  Color(0xFF7E3AF2),
  Color(0xFF0694A2),
  Color(0xFFE02424),
  Color(0xFF1C64F2),
  Color(0xFF0E9F6E),
  Color(0xFFFF5A1F),
];
Color _colorForIdx(int i) => _badgeColors[i % _badgeColors.length];

String _badge(String name) {
  final w = name.trim().split(RegExp(r'\s+'));
  return (w.length >= 2
          ? '${w[0][0]}${w[1][0]}'
          : name.substring(0, name.length >= 2 ? 2 : 1))
      .toUpperCase();
}

Color _statutColor(String s) {
  switch (s) {
    case 'BROUILLON':
      return _kGray;
    case 'EN_COURS':
      return _kBlue;
    case 'LIVRE':
      return _kPrimary;
    case 'ARCHIVE':
      return _kBrown;
    case 'ANNULE':
      return _kRed;
    default:
      return _kGray;
  }
}

IconData _statutIcon(String s) {
  switch (s) {
    case 'BROUILLON':
      return Icons.edit_note_outlined;
    case 'EN_COURS':
      return Icons.local_shipping_outlined;
    case 'LIVRE':
      return Icons.check_circle_outline;
    case 'ARCHIVE':
      return Icons.archive_outlined;
    case 'ANNULE':
      return Icons.cancel_outlined;
    default:
      return Icons.circle_outlined;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class DeploymentListScreen extends StatefulWidget {
  const DeploymentListScreen({super.key});
  @override
  State<DeploymentListScreen> createState() => _DeploymentListScreenState();
}

class _DeploymentListScreenState extends State<DeploymentListScreen> {
  bool _canEdit(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('ADMIN') ||
        role.contains('TECHNICIEN') ||
        role.contains('LOGISTICIEN');
  }

  bool _canDelete(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('SUPER') && role.contains('ADMIN');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeploymentListProvider>().charger(refresh: true);
    });
  }

  int _count(List<DeploymentModel> list, String statut) =>
      list.where((d) => d.statut == statut).length;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeploymentListProvider>();
    final all = prov.items;

    // KPI globaux
    final kpis = {
      'Total': all.length,
      'En cours': _count(all, 'EN_COURS'),
      'Livrés': _count(all, 'LIVRE'),
      'Brouillon': _count(all, 'BROUILLON'),
      'Annulés': _count(all, 'ANNULE'),
    };

    // Grouper par région
    final grouped = <String, List<DeploymentModel>>{};
    for (final d in all) {
      final key = d.regionName ?? d.healthName ?? 'Non défini';
      grouped.putIfAbsent(key, () => []).add(d);
    }
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (prov.hasError && all.isEmpty)
      return NetworkErrorWidget(onRetry: () => prov.charger(refresh: true));

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── KPI bar ────────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(14)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: kpis.entries
                  .map(
                    (e) => Column(children: [
                      Text('${e.value}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text(e.key,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 9)),
                    ]),
                  )
                  .toList()),
        ),

        // ── Filtres statut ─────────────────────────────────────────────────────
        SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                null,
                'BROUILLON',
                'EN_COURS',
                'LIVRE',
                'ARCHIVE',
                'ANNULE'
              ].map((s) {
                final sel = prov.filtreStatut == s;
                final color = s == null ? _kPrimary : _statutColor(s);
                final label = s == null ? 'Tous' : DeploymentStatut.label(s);
                return GestureDetector(
                  onTap: () => prov.setFiltreStatut(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? color : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: sel
                          ? null
                          : Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: sel ? Colors.white : color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            )),

        // ── Liste groupée par région ───────────────────────────────────────────
        Expanded(
          child: prov.isLoading && all.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : sortedGroups.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: () => prov.charger(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 90),
                        itemCount: sortedGroups.length,
                        itemBuilder: (context, index) {
                          final entry = sortedGroups[index];
                          return _RegionRow(
                            regionName: entry.key,
                            items: entry.value,
                            colorIdx: index,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _RegionDetailScreen(
                                    regionName: entry.key,
                                    items: entry.value,
                                    colorIdx: index,
                                    canEdit: _canEdit(context),
                                    canDelete: _canDelete(context),
                                    onRefresh: () =>
                                        prov.charger(refresh: true),
                                    onFiche: (d) => _ouvrirFiche(context, d),
                                  ),
                                )),
                          );
                        },
                      ),
                    ),
        ),
      ]),
      floatingActionButton: _canEdit(context)
          ? FloatingActionButton.extended(
              onPressed: () => _ouvrirFormulaire(context, null),
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  void _ouvrirFiche(BuildContext context, DeploymentModel dep) {
    final prov = context.read<DeploymentListProvider>();
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeploymentFicheScreen(deploiementId: dep.id),
        )).then((_) => prov.charger(refresh: true));
  }

  void _ouvrirFormulaire(BuildContext context, DeploymentModel? dep) {
    final prov = context.read<DeploymentListProvider>();
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeploymentFormScreen(deploymentExistant: dep),
        )).then((_) => prov.charger(refresh: true));
  }

  Widget _buildEmpty() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.local_shipping_outlined,
                color: _kPrimary, size: 40)),
        const SizedBox(height: 16),
        const Text('Aucun déploiement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Les déploiements apparaîtront ici',
            style: TextStyle(color: _kGray)),
      ]));
}

// ── Row région ────────────────────────────────────────────────────────────────
class _RegionRow extends StatelessWidget {
  final String regionName;
  final List<DeploymentModel> items;
  final int colorIdx;
  final VoidCallback onTap;
  const _RegionRow(
      {required this.regionName,
      required this.items,
      required this.colorIdx,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForIdx(colorIdx);
    final total = items.length;
    final enCours = items.where((d) => d.statut == 'EN_COURS').length;
    final livres = items.where((d) => d.statut == 'LIVRE').length;
    final annules = items.where((d) => d.statut == 'ANNULE').length;

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
                      color: color, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(_badge(regionName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
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
                    const SizedBox(height: 2),
                    Row(children: [
                      if (enCours > 0) _MiniTag('$enCours en cours', _kBlue),
                      if (enCours > 0 && livres > 0) const SizedBox(width: 4),
                      if (livres > 0) _MiniTag('$livres livrés', _kPrimary),
                      if (annules > 0 && (enCours > 0 || livres > 0))
                        const SizedBox(width: 4),
                      if (annules > 0) _MiniTag('$annules annulés', _kRed),
                    ]),
                  ])),
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
                            fontSize: 12))),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ]),
            ]),
          ),
          if (total > 0)
            SizedBox(
                height: 3,
                child: Row(children: [
                  if (livres > 0)
                    Expanded(flex: livres, child: Container(color: _kPrimary)),
                  if (enCours > 0)
                    Expanded(flex: enCours, child: Container(color: _kBlue)),
                  if (annules > 0)
                    Expanded(flex: annules, child: Container(color: _kRed)),
                  if (livres + enCours + annules < total)
                    Expanded(
                        flex: total - livres - enCours - annules,
                        child: Container(color: Colors.grey[200])),
                ])),
          Divider(height: 1, color: Colors.grey[100]),
        ]),
      ),
    );
  }
}

// ── Écran détail région ───────────────────────────────────────────────────────
class _RegionDetailScreen extends StatefulWidget {
  final String regionName;
  final List<DeploymentModel> items;
  final int colorIdx;
  final bool canEdit, canDelete;
  final VoidCallback onRefresh;
  final void Function(DeploymentModel) onFiche;

  const _RegionDetailScreen({
    required this.regionName,
    required this.items,
    required this.colorIdx,
    required this.canEdit,
    required this.canDelete,
    required this.onRefresh,
    required this.onFiche,
  });
  @override
  State<_RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<_RegionDetailScreen> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  String _query = '';
  String? _statutFilter;

  List<DeploymentModel> get _filtered => widget.items.where((d) {
        final q = _query.toLowerCase();
        final match = q.isEmpty ||
            d.codeDep.toLowerCase().contains(q) ||
            (d.healthName?.toLowerCase().contains(q) ?? false) ||
            (d.districtName?.toLowerCase().contains(q) ?? false);
        final statusOk = _statutFilter == null || d.statut == _statutFilter;
        return match && statusOk;
      }).toList();

  bool get _allSelected =>
      _filtered.isNotEmpty && _filtered.every((d) => _selected.contains(d.id));
  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        for (final d in _filtered) _selected.remove(d.id);
      } else {
        for (final d in _filtered) _selected.add(d.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selCount = _selected.length;
    final color = _colorForIdx(widget.colorIdx);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: selCount > 0 ? _kPrimary : Colors.white,
        foregroundColor: selCount > 0 ? Colors.white : const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: Icon(selCount > 0 ? Icons.close : Icons.arrow_back),
          onPressed: selCount > 0
              ? () => setState(() => _selected.clear())
              : () => Navigator.pop(context),
        ),
        title: selCount > 0
            ? Text('$selCount sélectionné${selCount > 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold))
            : Row(children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(_badge(widget.regionName),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11))),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(widget.regionName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis)),
              ]),
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color:
                      selCount > 0 ? Colors.white.withOpacity(0.2) : _kPrimary,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.items.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))),
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
                hintText: 'Rechercher (code, site, district)',
                hintStyle: const TextStyle(color: _kGray, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _kGray, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: _kGray,
                        onPressed: () {
                          setState(() => _query = '');
                          _searchCtrl.clear();
                        })
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
            )),
        // Filtres statut
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [
                null,
                'BROUILLON',
                'EN_COURS',
                'LIVRE',
                'ARCHIVE',
                'ANNULE'
              ]
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _statutFilter = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statutFilter == s
                                    ? _kPrimary
                                    : _kPrimary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                  s == null
                                      ? 'Tous'
                                      : DeploymentStatut.label(s),
                                  style: TextStyle(
                                      color: _statutFilter == s
                                          ? Colors.white
                                          : _kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                      )
                      .toList()),
            )),
        // Select all
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(children: [
              GestureDetector(
                  onTap: _toggleAll,
                  child: Row(children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _allSelected,
                          tristate: false,
                          onChanged: (_) => _toggleAll(),
                          activeColor: _kPrimary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        )),
                    const SizedBox(width: 8),
                    Text('Tout sélectionner',
                        style: const TextStyle(color: _kGray, fontSize: 12)),
                  ])),
              const Spacer(),
              Text(
                  '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: _kGray, fontSize: 12)),
            ])),
        const Divider(height: 1),
        // Liste
        Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('Aucun résultat',
                            style: TextStyle(color: _kGray)),
                      ]))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (ctx, i) {
                      final dep = filtered[i];
                      final isSel = _selected.contains(dep.id);
                      return _DepRow(
                        dep: dep,
                        isSelected: isSel,
                        canEdit: widget.canEdit,
                        canDelete: widget.canDelete,
                        onToggle: () => setState(() {
                          if (isSel)
                            _selected.remove(dep.id);
                          else
                            _selected.add(dep.id);
                        }),
                        onFiche: () => widget.onFiche(dep),
                        onEdit: () async {
                          await Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                  builder: (_) => DeploymentFormScreen(
                                      deploymentExistant: dep)));
                          widget.onRefresh();
                        },
                      );
                    },
                  )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DeploymentFormScreen()));
          widget.onRefresh();
          if (mounted) setState(() {});
        },
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Row déploiement ───────────────────────────────────────────────────────────
class _DepRow extends StatelessWidget {
  final DeploymentModel dep;
  final bool isSelected, canEdit, canDelete;
  final VoidCallback onToggle, onFiche, onEdit;
  const _DepRow(
      {required this.dep,
      required this.isSelected,
      required this.canEdit,
      required this.canDelete,
      required this.onToggle,
      required this.onFiche,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final color = _statutColor(dep.statut);
    final icon = _statutIcon(dep.statut);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: isSelected ? _kPrimary.withOpacity(0.05) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: _kPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            )),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dep.codeDep,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF111827))),
          const SizedBox(height: 2),
          if (dep.healthName != null)
            Text(dep.healthName!,
                style: const TextStyle(fontSize: 11, color: _kGray)),
          if (dep.districtName != null)
            Text(dep.districtName!,
                style: const TextStyle(fontSize: 11, color: _kGray)),
          Text('${dep.totalUnites} équipement${dep.totalUnites > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 10, color: _kGray)),
          if (dep.dateReception != null)
            Text(_formatDate(dep.dateReception),
                style: const TextStyle(fontSize: 10, color: _kGray)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 4),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(DeploymentStatut.label(dep.statut),
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w600))),
          if (canEdit) ...[
            const SizedBox(height: 6),
            Row(children: [
              _ActionBtn(Icons.visibility_outlined, _kPrimary, onFiche),
              const SizedBox(width: 4),
              _ActionBtn(Icons.edit_outlined, _kBlue, onEdit),
            ]),
          ],
        ]),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: color)));
}

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
