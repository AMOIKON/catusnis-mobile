// lib/features/acquisitions/screens/acquisition_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/acquisition_model.dart';
import '../services/acquisition_service.dart';
import 'acquisition_form_screen.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF1A56DB);
const _kGreen = Color(0xFF057A55);
const _kRed = Color(0xFFC81E1E);
const _kOrange = Color(0xFFC27803);
const _kBlue = Color(0xFF1565C0);
const _kGray = Color(0xFF6B7280);
const _kBg = Color(0xFFF3F4F6);

// ── Palettes pour les badges de type ─────────────────────────────────────────
const _badgeColors = [
  Color(0xFF1A56DB),
  Color(0xFF057A55),
  Color(0xFFC27803),
  Color(0xFF7E3AF2),
  Color(0xFF0694A2),
  Color(0xFFE02424),
  Color(0xFF1C64F2),
  Color(0xFF0E9F6E),
  Color(0xFFFF5A1F),
];

Color _colorForIndex(int i) => _badgeColors[i % _badgeColors.length];

String _badge(String typeName) {
  final words = typeName.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return typeName.substring(0, typeName.length >= 2 ? 2 : 1).toUpperCase();
}

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class AcquisitionScreen extends StatefulWidget {
  const AcquisitionScreen({super.key});
  @override
  State<AcquisitionScreen> createState() => _AcquisitionScreenState();
}

class _AcquisitionScreenState extends State<AcquisitionScreen> {
  final AcquisitionService _service = AcquisitionService();
  List<AcquisitionModel> _allItems = [];
  bool _loading = false;
  bool _hasError = false;
  String? _selectedStatus;

  final List<_StatusFilter> _filters = const [
    _StatusFilter(null, 'Tous', Icons.all_inclusive_outlined, _kPrimary),
    _StatusFilter(
        'DISPONIBLE', 'Disponible', Icons.check_circle_outline, _kGreen),
    _StatusFilter('DEPLOYE', 'Déployé', Icons.local_shipping_outlined, _kBlue),
    _StatusFilter('EN_PANNE', 'En panne', Icons.warning_amber_outlined, _kRed),
    _StatusFilter('MAINTENANCE', 'Maintenance', Icons.build_outlined, _kOrange),
  ];

  bool _canEdit(BuildContext ctx) {
    final role = ctx.read<AuthProvider>().user?.role.toUpperCase() ?? '';
    return role.contains('ADMIN') || role.contains('TECHNICIEN');
  }

  bool _canDelete(BuildContext ctx) {
    final role = ctx.read<AuthProvider>().user?.role.toUpperCase() ?? '';
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
      List<AcquisitionModel> all = [];
      int page = 0, total = 0;
      do {
        final result = await _service.getAcquisitions(page: page, size: 50);
        all.addAll(List<AcquisitionModel>.from(result['items'] as List));
        total = result['totalElements'] as int;
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

  List<AcquisitionModel> get _filtered => _selectedStatus == null
      ? _allItems
      : _allItems.where((a) => a.status == _selectedStatus).toList();

  Map<String, List<AcquisitionModel>> get _grouped {
    final map = <String, List<AcquisitionModel>>{};
    for (final acq in _filtered) {
      final key = acq.typeName ?? 'Type non défini';
      map.putIfAbsent(key, () => []).add(acq);
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length)));
  }

  int _countStatus(String status) =>
      _allItems.where((a) => a.status == status).length;

  @override
  Widget build(BuildContext context) {
    if (_hasError && _allItems.isEmpty)
      return NetworkErrorWidget(onRetry: _loadAll);

    final grouped = _grouped;

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
            _KpiPill('Disponible', _countStatus('DISPONIBLE'),
                const Color(0xFF34D399)),
            _KpiPill(
                'Déployé', _countStatus('DEPLOYE'), const Color(0xFF93C5FD)),
            _KpiPill(
                'En panne', _countStatus('EN_PANNE'), const Color(0xFFFCA5A5)),
            _KpiPill('Maintenance', _countStatus('MAINTENANCE'),
                const Color(0xFFFCD34D)),
          ]),
        ),

        // ── Filtres ────────────────────────────────────────────────────────────
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final sel = _selectedStatus == f.status;
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = f.status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? f.color : f.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: sel
                        ? null
                        : Border.all(color: f.color.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(f.icon, size: 13, color: sel ? Colors.white : f.color),
                    const SizedBox(width: 5),
                    Text(f.label,
                        style: TextStyle(
                            color: sel ? Colors.white : f.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              );
            },
          ),
        ),

        // ── Info filtre actif ──────────────────────────────────────────────────
        if (_selectedStatus != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              Text(
                  '${_filtered.length} équipement(s) · ${grouped.length} type(s)',
                  style: const TextStyle(fontSize: 12, color: _kGray)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedStatus = null),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.close, size: 12, color: Colors.red),
                    SizedBox(width: 3),
                    Text('Effacer',
                        style: TextStyle(fontSize: 11, color: Colors.red)),
                  ]),
                ),
              ),
            ]),
          ),

        // ── Liste des types ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : grouped.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _loadAll,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped.entries.elementAt(index);
                          // items de ce type dans TOUS les statuts (pour les compteurs)
                          final allOfType = _allItems
                              .where((a) =>
                                  (a.typeName ?? 'Type non défini') ==
                                  entry.key)
                              .toList();
                          return _TypeRow(
                            typeName: entry.key,
                            items: entry.value,
                            allItems: allOfType,
                            colorIdx: index,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => _TypeDetailScreen(
                                        typeName: entry.key,
                                        items: allOfType,
                                        colorIdx: index,
                                        canEdit: _canEdit(context),
                                        canDelete: _canDelete(context),
                                        onRefresh: _loadAll,
                                      )),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),

      // ── FAB ───────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AcquisitionFormScreen()));
          _loadAll();
        },
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: const Icon(Icons.inventory_2_outlined,
                  color: _kPrimary, size: 40)),
          const SizedBox(height: 16),
          Text(
              _selectedStatus != null
                  ? 'Aucun équipement avec ce statut'
                  : 'Aucune acquisition',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(
              _selectedStatus != null
                  ? 'Essayez un autre filtre'
                  : 'Les acquisitions apparaîtront ici',
              style: const TextStyle(color: _kGray)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROW TYPE (style Image 2 — badge 2 lettres + nom + compteur)
// ═══════════════════════════════════════════════════════════════════════════════
class _TypeRow extends StatelessWidget {
  final String typeName;
  final List<AcquisitionModel> items; // items filtrés
  final List<AcquisitionModel> allItems; // tous items du type
  final int colorIdx;
  final VoidCallback onTap;

  const _TypeRow(
      {required this.typeName,
      required this.items,
      required this.allItems,
      required this.colorIdx,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForIndex(colorIdx);
    final badge = _badge(typeName);
    final total = allItems.length;
    final dispo = allItems.where((a) => a.status == 'DISPONIBLE').length;
    final panne = allItems.where((a) => a.status == 'EN_PANNE').length;
    final maint = allItems.where((a) => a.status == 'MAINTENANCE').length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              // ── Badge 2 lettres ──────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(badge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 14),

              // ── Nom + sous-infos ─────────────────────────────────────────────
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(typeName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF111827)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (dispo > 0) _MiniTag('$dispo dispo', _kGreen),
                      if (dispo > 0 && panne > 0) const SizedBox(width: 4),
                      if (panne > 0) _MiniTag('$panne panne', _kRed),
                      if (panne > 0 && maint > 0) const SizedBox(width: 4),
                      if (maint > 0) _MiniTag('$maint maint.', _kOrange),
                    ]),
                  ])),

              // ── Compteur total + flèche ──────────────────────────────────────
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

          // ── Barre de progression colorée ─────────────────────────────────────
          if (total > 0)
            SizedBox(
              height: 3,
              child: Row(children: [
                if (dispo > 0)
                  Expanded(flex: dispo, child: Container(color: _kGreen)),
                if (allItems.where((a) => a.status == 'DEPLOYE').length > 0)
                  Expanded(
                      flex: allItems.where((a) => a.status == 'DEPLOYE').length,
                      child: Container(color: _kBlue)),
                if (panne > 0)
                  Expanded(flex: panne, child: Container(color: _kRed)),
                if (maint > 0)
                  Expanded(flex: maint, child: Container(color: _kOrange)),
                if (dispo +
                        allItems.where((a) => a.status == 'DEPLOYE').length +
                        panne +
                        maint <
                    total)
                  Expanded(
                      flex: total -
                          dispo -
                          allItems.where((a) => a.status == 'DEPLOYE').length -
                          panne -
                          maint,
                      child: Container(color: Colors.grey[200])),
              ]),
            ),

          Divider(height: 1, color: Colors.grey[100]),
        ]),
      ),
    );
  }
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

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN DÉTAIL D'UN TYPE (style Image 2 droite — checkboxes + search)
// ═══════════════════════════════════════════════════════════════════════════════
class _TypeDetailScreen extends StatefulWidget {
  final String typeName;
  final List<AcquisitionModel> items;
  final int colorIdx;
  final bool canEdit, canDelete;
  final VoidCallback onRefresh;

  const _TypeDetailScreen({
    required this.typeName,
    required this.items,
    required this.colorIdx,
    required this.canEdit,
    required this.canDelete,
    required this.onRefresh,
  });

  @override
  State<_TypeDetailScreen> createState() => _TypeDetailScreenState();
}

class _TypeDetailScreenState extends State<_TypeDetailScreen> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  String _query = '';
  String? _statusFilter;

  List<AcquisitionModel> get _filtered {
    var list = widget.items.where((a) {
      final q = _query.toLowerCase();
      final match = q.isEmpty ||
          a.tag.toLowerCase().contains(q) ||
          a.serial.toLowerCase().contains(q) ||
          (a.partnerName?.toLowerCase().contains(q) ?? false);
      final statusOk = _statusFilter == null || a.status == _statusFilter;
      return match && statusOk;
    }).toList();
    return list;
  }

  bool get _allSelected =>
      _filtered.isNotEmpty && _filtered.every((a) => _selected.contains(a.id));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        for (final a in _filtered) _selected.remove(a.id);
      } else {
        for (final a in _filtered) _selected.add(a.id);
      }
    });
  }

  Color get _badgeColor => _colorForIndex(widget.colorIdx);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selCount = _selected.length;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: selCount > 0 ? _kPrimary : Colors.white,
        foregroundColor: selCount > 0 ? Colors.white : const Color(0xFF111827),
        elevation: 0,
        leading: selCount > 0
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selected.clear()))
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context)),
        title: selCount > 0
            ? Text('$selCount sélectionné${selCount > 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold))
            : Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text(_badge(widget.typeName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(widget.typeName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis)),
              ]),
        actions: selCount > 0
            ? [
                if (widget.canEdit)
                  IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier',
                      onPressed: () {/* modifier sélection */}),
                IconButton(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    tooltip: 'Exporter',
                    onPressed: () {/* exporter */}),
              ]
            : [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${widget.items.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
      ),
      body: Column(children: [
        // ── Barre de recherche ─────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher (tag, serial, partenaire)',
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
          ),
        ),

        // ── Filtres statut ─────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in [
                null,
                'DISPONIBLE',
                'DEPLOYE',
                'EN_PANNE',
                'MAINTENANCE'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _statusFilter = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusFilter == s
                            ? _kPrimary
                            : _kPrimary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_labelFor(s),
                          style: TextStyle(
                              color:
                                  _statusFilter == s ? Colors.white : _kPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
            ]),
          ),
        ),

        // ── Select all + count ─────────────────────────────────────────────────
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
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Tout sélectionner',
                    style: TextStyle(color: _kGray, fontSize: 12)),
              ]),
            ),
            const Spacer(),
            Text('${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                style: const TextStyle(color: _kGray, fontSize: 12)),
          ]),
        ),

        const Divider(height: 1),

        // ── Liste des équipements ──────────────────────────────────────────────
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
                    ]))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (ctx, i) {
                    final acq = filtered[i];
                    final isSelected = _selected.contains(acq.id);
                    return _AcqRow(
                      acquisition: acq,
                      isSelected: isSelected,
                      canEdit: widget.canEdit,
                      canDelete: widget.canDelete,
                      onToggle: () => setState(() {
                        if (isSelected)
                          _selected.remove(acq.id);
                        else
                          _selected.add(acq.id);
                      }),
                      onEdit: () async {
                        await Navigator.push(
                            ctx,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AcquisitionFormScreen(model: acq)));
                        widget.onRefresh();
                        if (mounted) Navigator.pop(ctx);
                      },
                      onDelete: () => _confirmDelete(ctx, acq),
                    );
                  },
                ),
        ),
      ]),

      // ── FAB ───────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AcquisitionFormScreen()));
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

  String _labelFor(String? s) {
    switch (s) {
      case 'DISPONIBLE':
        return 'Disponible';
      case 'DEPLOYE':
        return 'Déployé';
      case 'EN_PANNE':
        return 'En panne';
      case 'MAINTENANCE':
        return 'Maintenance';
      default:
        return 'Tous';
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, AcquisitionModel acq) async {
    final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Confirmer la suppression'),
              content: Text(
                  'Supprimer "${acq.tag}" ?\nCette action est irréversible.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Supprimer',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
    if (confirm != true) return;
    try {
      await AcquisitionService().deleteAcquisition(acq.id);
      widget.onRefresh();
      if (mounted) Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Acquisition supprimée'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROW ÉQUIPEMENT (style Image 2 — checkbox + tag + infos + statut)
// ═══════════════════════════════════════════════════════════════════════════════
class _AcqRow extends StatelessWidget {
  final AcquisitionModel acquisition;
  final bool isSelected, canEdit, canDelete;
  final VoidCallback onToggle, onEdit, onDelete;

  const _AcqRow({
    required this.acquisition,
    required this.isSelected,
    required this.canEdit,
    required this.canDelete,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (acquisition.status) {
      case 'DISPONIBLE':
        return _kGreen;
      case 'DEPLOYE':
        return _kBlue;
      case 'EN_PANNE':
        return _kRed;
      case 'MAINTENANCE':
        return _kOrange;
      default:
        return _kGray;
    }
  }

  IconData get _statusIcon {
    switch (acquisition.status) {
      case 'DISPONIBLE':
        return Icons.check_circle_outline;
      case 'DEPLOYE':
        return Icons.cloud_done_outlined;
      case 'EN_PANNE':
        return Icons.error_outline;
      case 'MAINTENANCE':
        return Icons.build_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: isSelected ? _kPrimary.withOpacity(0.05) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // ── Checkbox ────────────────────────────────────────────────────────────
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: isSelected,
            onChanged: (_) => onToggle(),
            activeColor: _kPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),

        // ── Infos ────────────────────────────────────────────────────────────────
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            acquisition.tag.length > 32
                ? '${acquisition.tag.substring(0, 29)}...'
                : acquisition.tag,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 2),
          Text('S/N : ${acquisition.serial}',
              style: const TextStyle(fontSize: 11, color: _kGray)),
          if (acquisition.partnerName != null)
            Text(acquisition.partnerName!,
                style: const TextStyle(fontSize: 11, color: _kGray)),
          if (acquisition.dateAcq != null)
            Text('Acq. : ${_formatDate(acquisition.dateAcq)}',
                style: const TextStyle(fontSize: 10, color: _kGray)),
        ])),

        // ── Statut + Actions ─────────────────────────────────────────────────────
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_statusIcon, color: _statusColor, size: 16),
          ),
          if (canEdit || canDelete) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (canEdit) _ActionBtn(Icons.edit_outlined, _kPrimary, onEdit),
              if (canEdit && canDelete) const SizedBox(width: 6),
              if (canDelete) _ActionBtn(Icons.delete_outline, _kRed, onDelete),
            ]),
          ],
        ]),
      ]),
    );
  }
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
          child: Icon(icon, size: 14, color: color),
        ),
      );
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

class _StatusFilter {
  final String? status;
  final String label;
  final IconData icon;
  final Color color;
  const _StatusFilter(this.status, this.label, this.icon, this.color);
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
