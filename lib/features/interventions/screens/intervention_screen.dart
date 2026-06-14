// lib/features/interventions/screens/intervention_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/intervention_model.dart';
import '../services/intervention_service.dart';
import 'intervention_form_screen.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFC27803);
const _kBlue = Color(0xFF1565C0);
const _kGreen = Color(0xFF057A55);
const _kRed = Color(0xFFC81E1E);
const _kGray = Color(0xFF6B7280);
const _kBg = Color(0xFFFFF8F0);

const _badgeColors = [
  Color(0xFFC27803),
  Color(0xFF1565C0),
  Color(0xFF057A55),
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

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class InterventionScreen extends StatefulWidget {
  const InterventionScreen({super.key});
  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  final InterventionService _service = InterventionService();
  List<InterventionModel> _allItems = [];
  bool _loading = false;
  bool _hasError = false;
  String? _selectedType;

  bool _canEdit(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('ADMIN') || role.contains('TECHNICIEN');
  }

  bool _canDelete(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('SUPER') && role.contains('ADMIN');
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      List<InterventionModel> all = [];
      int page = 0, total = 0;
      do {
        final result = await _service.getInterventions(page: page, size: 50);
        all.addAll(List<InterventionModel>.from(result['items'] as List));
        total = (result['totalElements'] as num).toInt();
        page++;
      } while (all.length < total);
      if (!mounted) return;
      setState(() {
        _allItems = all;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  List<InterventionModel> get _filtered => _selectedType == null
      ? _allItems
      : _allItems.where((i) => i.typeInter == _selectedType).toList();

  Map<String, List<InterventionModel>> get _groupedByAction {
    final map = <String, List<InterventionModel>>{};
    for (final inter in _filtered) {
      map.putIfAbsent(inter.actionInter, () => []).add(inter);
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length)));
  }

  int _countType(String type) =>
      _allItems.where((i) => i.typeInter == type).length;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _allItems.isEmpty)
      return NetworkErrorWidget(onRetry: _loadAll);
    final grouped = _groupedByAction;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── KPI bar ────────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(14)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _KpiPill('Total', _allItems.length, Colors.white),
            _KpiPill(
                'En ligne', _countType('EN_LIGNE'), const Color(0xFFBAE6FD)),
            _KpiPill(
                'Sur site', _countType('SUR_SITE'), const Color(0xFFBBF7D0)),
            _KpiPill('Actions', grouped.length, const Color(0xFFFDE68A)),
            _KpiPill(
                'Attente',
                _allItems.where((i) => i.enAttenteMaintenance).length,
                const Color(0xFFFCA5A5)),
          ]),
        ),

        // ── Filtres type ───────────────────────────────────────────────────────
        SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildFilterChip(
                    null, 'Tous', Icons.all_inclusive_outlined, _kPrimary),
                _buildFilterChip(
                    'EN_LIGNE', 'En ligne', Icons.wifi_outlined, _kBlue),
                _buildFilterChip('SUR_SITE', 'Sur site',
                    Icons.location_on_outlined, _kGreen),
              ],
            )),

        // ── Liste groupée par action ───────────────────────────────────────────
        Expanded(
          child: _loading && _allItems.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : grouped.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _loadAll,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 90),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          final allOfAction = _allItems
                              .where((i) => i.actionInter == entry.key)
                              .toList();
                          return _ActionRow(
                            actionName: entry.key,
                            items: entry.value,
                            allItems: allOfAction,
                            colorIdx: index,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _ActionDetailScreen(
                                    actionName: entry.key,
                                    items: allOfAction,
                                    colorIdx: index,
                                    canEdit: _canEdit(context),
                                    canDelete: _canDelete(context),
                                    onRefresh: _loadAll,
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
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InterventionFormScreen()));
                _loadAll();
              },
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildFilterChip(
      String? type, String label, IconData icon, Color color) {
    final sel = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: sel ? null : Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: sel ? Colors.white : color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: sel ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child:
                const Icon(Icons.build_outlined, color: _kPrimary, size: 40)),
        const SizedBox(height: 16),
        const Text('Aucune intervention',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Les interventions apparaîtront ici',
            style: TextStyle(color: _kGray)),
      ]));
}

// ── Row action ────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final String actionName;
  final List<InterventionModel> items;
  final List<InterventionModel> allItems;
  final int colorIdx;
  final VoidCallback onTap;
  const _ActionRow(
      {required this.actionName,
      required this.items,
      required this.allItems,
      required this.colorIdx,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForIdx(colorIdx);
    final total = allItems.length;
    final enLigne = allItems.where((i) => i.typeInter == 'EN_LIGNE').length;
    final surSite = allItems.where((i) => i.typeInter == 'SUR_SITE').length;
    final attente = allItems.where((i) => i.enAttenteMaintenance).length;

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
                    child: Text(_badge(actionName),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(actionName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(children: [
                        if (enLigne > 0) _MiniTag('$enLigne en ligne', _kBlue),
                        if (enLigne > 0 && surSite > 0)
                          const SizedBox(width: 4),
                        if (surSite > 0) _MiniTag('$surSite sur site', _kGreen),
                        if (attente > 0) ...[
                          const SizedBox(width: 4),
                          _MiniTag('$attente attente', _kRed),
                        ],
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
                    if (enLigne > 0)
                      Expanded(flex: enLigne, child: Container(color: _kBlue)),
                    if (surSite > 0)
                      Expanded(flex: surSite, child: Container(color: _kGreen)),
                    if (enLigne + surSite < total)
                      Expanded(
                          flex: total - enLigne - surSite,
                          child: Container(color: Colors.grey[200])),
                  ])),
            Divider(height: 1, color: Colors.grey[100]),
          ])),
    );
  }
}

// ── Écran détail action ───────────────────────────────────────────────────────
class _ActionDetailScreen extends StatefulWidget {
  final String actionName;
  final List<InterventionModel> items;
  final int colorIdx;
  final bool canEdit, canDelete;
  final VoidCallback onRefresh;

  const _ActionDetailScreen({
    required this.actionName,
    required this.items,
    required this.colorIdx,
    required this.canEdit,
    required this.canDelete,
    required this.onRefresh,
  });
  @override
  State<_ActionDetailScreen> createState() => _ActionDetailScreenState();
}

class _ActionDetailScreenState extends State<_ActionDetailScreen> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  String _query = '';
  String? _typeFilter;

  List<InterventionModel> get _filtered => widget.items.where((i) {
        final q = _query.toLowerCase();
        final match = q.isEmpty ||
            i.codeInter.toLowerCase().contains(q) ||
            (i.healthName?.toLowerCase().contains(q) ?? false) ||
            (i.technicianName?.toLowerCase().contains(q) ?? false);
        final typeOk = _typeFilter == null || i.typeInter == _typeFilter;
        return match && typeOk;
      }).toList();

  bool get _allSelected =>
      _filtered.isNotEmpty && _filtered.every((i) => _selected.contains(i.id));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        for (final i in _filtered) _selected.remove(i.id);
      } else {
        for (final i in _filtered) _selected.add(i.id);
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
                    child: Text(_badge(widget.actionName),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11))),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(widget.actionName,
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
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher (code, site, technicien)',
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
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [null, 'EN_LIGNE', 'SUR_SITE']
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _typeFilter = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _typeFilter == t
                                    ? _kPrimary
                                    : _kPrimary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                  t == null
                                      ? 'Tous'
                                      : (t == 'EN_LIGNE'
                                          ? 'En ligne'
                                          : 'Sur site'),
                                  style: TextStyle(
                                      color: _typeFilter == t
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
                    const Text('Tout sélectionner',
                        style: TextStyle(color: _kGray, fontSize: 12)),
                  ])),
              const Spacer(),
              Text(
                  '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: _kGray, fontSize: 12)),
            ])),
        const Divider(height: 1),
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
                      final inter = filtered[i];
                      final isSel = _selected.contains(inter.id);
                      return _InterRow(
                        inter: inter,
                        isSelected: isSel,
                        canEdit: widget.canEdit,
                        canDelete: widget.canDelete,
                        onToggle: () => setState(() {
                          if (isSel)
                            _selected.remove(inter.id);
                          else
                            _selected.add(inter.id);
                        }),
                        onEdit: () async {
                          await Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                  builder: (_) => InterventionFormScreen(
                                      intervention: inter)));
                          widget.onRefresh();
                        },
                      );
                    },
                  )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const InterventionFormScreen()));
          widget.onRefresh();
          if (mounted) setState(() {});
        },
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Row intervention ──────────────────────────────────────────────────────────
class _InterRow extends StatelessWidget {
  final InterventionModel inter;
  final bool isSelected, canEdit, canDelete;
  final VoidCallback onToggle, onEdit;
  const _InterRow(
      {required this.inter,
      required this.isSelected,
      required this.canEdit,
      required this.canDelete,
      required this.onToggle,
      required this.onEdit});

  Color get _typeColor => inter.typeInter == 'EN_LIGNE' ? _kBlue : _kGreen;
  IconData get _typeIcon => inter.typeInter == 'EN_LIGNE'
      ? Icons.wifi_outlined
      : Icons.location_on_outlined;

  @override
  Widget build(BuildContext context) {
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
          Text(inter.codeInter,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF111827))),
          const SizedBox(height: 2),
          if (inter.healthName != null)
            Text(inter.healthName!,
                style: const TextStyle(fontSize: 11, color: _kGray)),
          if (inter.technicianName != null)
            Text('Tech. : ${inter.technicianName}',
                style: const TextStyle(fontSize: 11, color: _kGray)),
          if (inter.dateInter != null)
            Text(_formatDate(inter.dateInter),
                style: const TextStyle(fontSize: 10, color: _kGray)),
          if (inter.enAttenteMaintenance)
            _MiniTag('En attente maintenance', _kRed),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(_typeIcon, color: _typeColor, size: 16)),
          const SizedBox(height: 4),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  inter.typeInter == 'EN_LIGNE' ? 'En ligne' : 'Sur site',
                  style: TextStyle(
                      color: _typeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600))),
          if (canEdit) ...[
            const SizedBox(height: 6),
            GestureDetector(
                onTap: onEdit,
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: _kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.edit_outlined,
                        size: 14, color: _kBlue))),
          ],
        ]),
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
  Widget build(BuildContext context) => Column(children: [
        Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: TextStyle(color: color.withOpacity(0.85), fontSize: 9)),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      );
}

// ✅ CORRIGÉ : return iso au lieu de return iso ?? ''
// Après if (iso == null || iso.isEmpty) return '', Dart sait que iso est non-null
String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
