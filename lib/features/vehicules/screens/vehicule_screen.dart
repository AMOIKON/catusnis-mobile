// lib/features/vehicules/screens/vehicule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/vehicule_model.dart';
import '../providers/vehicule_provider.dart';
import '../widgets/vehicule_card.dart';
import 'vehicule_form_screen.dart';
import 'incident_form_screen.dart';
import 'maintenance_form_screen.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2E7D32);
const _kBlue = Color(0xFF1565C0);
const _kOrange = Color(0xFFFF6F00);
const _kRed = Color(0xFFC62828);
const _kPurple = Color(0xFF6A1B9A);
const _kGray = Color(0xFF6B7280);
const _kBg = Color(0xFFF4FAF6);

const _badgeColors = [
  Color(0xFF2E7D32),
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

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL — 5 onglets
// ═══════════════════════════════════════════════════════════════════════════════
class VehiculeScreen extends StatefulWidget {
  const VehiculeScreen({super.key});
  @override
  State<VehiculeScreen> createState() => _VehiculeScreenState();
}

class _VehiculeScreenState extends State<VehiculeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = [
    _TabInfo('Engins', Icons.directions_car_outlined, _kPrimary),
    _TabInfo('Affectations', Icons.person_pin_outlined, _kBlue),
    _TabInfo('Incidents', Icons.warning_amber_outlined, _kOrange),
    _TabInfo('Maintenances', Icons.build_outlined, _kRed),
    _TabInfo('Alertes', Icons.notifications_outlined, _kPurple),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<VehiculeProvider>().setTab(_tabCtrl.index);
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculeProvider>().charger(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _canEdit(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('ADMIN') ||
        role.contains('LOGISTICIEN') ||
        role.contains('TECHNICIEN');
  }

  bool _canDelete(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('SUPER') && role.contains('ADMIN') ||
        role.contains('ADMIN');
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VehiculeProvider>();
    final alertCount = prov.alertesExpireesCount;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── Header KPI ─────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(14)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _KpiPill('Total', prov.total, Colors.white),
            _KpiPill(
                'Dispo',
                prov.vehicules.where((v) => v.statut == 'DISPONIBLE').length,
                const Color(0xFFBBF7D0)),
            _KpiPill(
                'Mission',
                prov.vehicules.where((v) => v.statut == 'EN_MISSION').length,
                const Color(0xFFBAE6FD)),
            _KpiPill(
                'Panne',
                prov.vehicules.where((v) => v.statut == 'EN_PANNE').length,
                const Color(0xFFFCA5A5)),
            if (alertCount > 0)
              _KpiPill('Alertes!', alertCount, const Color(0xFFFDE68A))
            else
              _KpiPill(
                  'Maint.',
                  prov.vehicules
                      .where((v) => v.statut == 'EN_MAINTENANCE')
                      .length,
                  const Color(0xFFFDE68A)),
          ]),
        ),

        // ── TabBar ─────────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: _kPrimary,
            labelColor: _kPrimary,
            unselectedLabelColor: _kGray,
            labelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: _tabs.asMap().entries.map((e) {
              final i = e.key;
              final tab = e.value;
              final badge = i == 4 && alertCount > 0;
              return Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(tab.icon, size: 15),
                const SizedBox(width: 4),
                Text(tab.label),
                if (badge) ...[
                  const SizedBox(width: 4),
                  Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: _kRed, shape: BoxShape.circle),
                      child: Center(
                          child: Text('$alertCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)))),
                ],
              ]));
            }).toList(),
          ),
        ),

        // ── Contenu ────────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _EnginsList(
                  canEdit: _canEdit(context), canDelete: _canDelete(context)),
              _SimpleList<VehiculeAffectationModel>(
                loading: prov.loading,
                error: prov.error,
                items: prov.affectations,
                onRefresh: () => prov.charger(refresh: true),
                builder: (a) =>
                    AffectationCard(affectation: a, canEdit: _canEdit(context)),
                emptyIcon: Icons.person_pin_outlined,
                emptyMsg: 'Aucune affectation',
              ),
              _SimpleList<VehiculeIncidentModel>(
                loading: prov.loading,
                error: prov.error,
                items: prov.incidents,
                onRefresh: () => prov.charger(refresh: true),
                builder: (i) => IncidentCard(
                  incident: i,
                  canEdit: _canEdit(context),
                  canDelete: _canDelete(context),
                  onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => IncidentFormScreen(incident: i)))
                      .then((_) => prov.charger(refresh: true)),
                  onDelete: () => prov.supprimerIncident(i.id),
                ),
                emptyIcon: Icons.warning_amber_outlined,
                emptyMsg: 'Aucun incident signalé',
              ),
              _SimpleList<VehiculeMaintenanceModel>(
                loading: prov.loading,
                error: prov.error,
                items: prov.maintenances,
                onRefresh: () => prov.charger(refresh: true),
                builder: (m) => MaintenanceCard(
                  maintenance: m,
                  canEdit: _canEdit(context),
                  canDelete: _canDelete(context),
                  onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MaintenanceFormScreen(maintenance: m)))
                      .then((_) => prov.charger(refresh: true)),
                  onDelete: () => prov.supprimerMaintenance(m.id),
                ),
                emptyIcon: Icons.build_outlined,
                emptyMsg: 'Aucune maintenance planifiée',
              ),
              _AlertesList(),
            ],
          ),
        ),
      ]),
      floatingActionButton: _canEdit(context) ? _buildFab(context) : null,
    );
  }

  Widget? _buildFab(BuildContext context) {
    final prov = context.read<VehiculeProvider>();
    switch (_tabCtrl.index) {
      case 0:
        return FloatingActionButton.extended(
          backgroundColor: _kPrimary,
          icon: const Icon(Icons.directions_car, color: Colors.white),
          label: const Text('Nouvel engin',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VehiculeFormScreen()))
              .then((_) => prov.charger(refresh: true)),
        );
      case 2:
        return FloatingActionButton.extended(
          backgroundColor: _kOrange,
          icon: const Icon(Icons.warning_amber, color: Colors.white),
          label: const Text('Signaler',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const IncidentFormScreen()))
              .then((_) => prov.charger(refresh: true)),
        );
      case 3:
        return FloatingActionButton.extended(
          backgroundColor: _kRed,
          icon: const Icon(Icons.build, color: Colors.white),
          label: const Text('Planifier',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MaintenanceFormScreen()))
              .then((_) => prov.charger(refresh: true)),
        );
      default:
        return null;
    }
  }
}

// ── Tab Engins — groupé par type avec badges ──────────────────────────────────
class _EnginsList extends StatefulWidget {
  final bool canEdit, canDelete;
  const _EnginsList({required this.canEdit, required this.canDelete});
  @override
  State<_EnginsList> createState() => _EnginsListState();
}

class _EnginsListState extends State<_EnginsList> {
  String? _statutFilter;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VehiculeProvider>();
    if (prov.loading && prov.vehicules.isEmpty)
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    if (prov.error != null && prov.vehicules.isEmpty)
      return NetworkErrorWidget(
          message: prov.error!,
          onRetry: () =>
              context.read<VehiculeProvider>().charger(refresh: true));

    final filtered = _statutFilter == null
        ? prov.vehicules
        : prov.vehicules.where((v) => v.statut == _statutFilter).toList();

    // Grouper par type
    final grouped = <String, List<VehiculeModel>>{};
    for (final v in filtered) {
      grouped.putIfAbsent(v.type, () => []).add(v);
    }
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(children: [
      // Filtres statut
      Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [
              null,
              'DISPONIBLE',
              'EN_MISSION',
              'EN_PANNE',
              'EN_MAINTENANCE',
              'RETIRE'
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
                            child: Text(_labelStatut(s),
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

      Expanded(
        child: filtered.isEmpty
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(Icons.directions_car_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('Aucun engin', style: TextStyle(color: _kGray)),
                  ]))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: () =>
                    context.read<VehiculeProvider>().charger(refresh: true),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: sortedGroups.length,
                  itemBuilder: (ctx, index) {
                    final entry = sortedGroups[index];
                    return _TypeVehiculeRow(
                      typeName: entry.key,
                      items: entry.value,
                      allItems: prov.vehicules
                          .where((v) => v.type == entry.key)
                          .toList(),
                      colorIdx: index,
                      onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => _TypeVehiculeDetail(
                              typeName: entry.key,
                              items: prov.vehicules
                                  .where((v) => v.type == entry.key)
                                  .toList(),
                              colorIdx: index,
                              canEdit: widget.canEdit,
                              canDelete: widget.canDelete,
                              onRefresh: () => context
                                  .read<VehiculeProvider>()
                                  .charger(refresh: true),
                            ),
                          )),
                    );
                  },
                ),
              ),
      ),
    ]);
  }

  String _labelStatut(String? s) {
    switch (s) {
      case 'DISPONIBLE':
        return 'Disponible';
      case 'EN_MISSION':
        return 'En mission';
      case 'EN_PANNE':
        return 'En panne';
      case 'EN_MAINTENANCE':
        return 'Maintenance';
      case 'RETIRE':
        return 'Retiré';
      default:
        return 'Tous';
    }
  }
}

// ── Row type véhicule ─────────────────────────────────────────────────────────
class _TypeVehiculeRow extends StatelessWidget {
  final String typeName;
  final List<VehiculeModel> items, allItems;
  final int colorIdx;
  final VoidCallback onTap;
  const _TypeVehiculeRow(
      {required this.typeName,
      required this.items,
      required this.allItems,
      required this.colorIdx,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForIdx(colorIdx);
    final total = allItems.length;
    final dispo = allItems.where((v) => v.statut == 'DISPONIBLE').length;
    final panne = allItems.where((v) => v.statut == 'EN_PANNE').length;
    final alert = allItems.where((v) => v.hasAlert).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
          color: Colors.white,
          child: Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(_badge(typeName),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(typeName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(children: [
                          if (dispo > 0) _MiniTag('$dispo dispo', _kPrimary),
                          if (dispo > 0 && panne > 0) const SizedBox(width: 4),
                          if (panne > 0) _MiniTag('$panne panne', _kRed),
                          if (alert > 0) ...[
                            const SizedBox(width: 4),
                            _MiniTag('$alert alertes', _kOrange)
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
                    Icon(Icons.chevron_right,
                        color: Colors.grey[400], size: 20),
                  ]),
                ])),
            if (total > 0)
              SizedBox(
                  height: 3,
                  child: Row(children: [
                    if (dispo > 0)
                      Expanded(flex: dispo, child: Container(color: _kPrimary)),
                    if (allItems.where((v) => v.statut == 'EN_MISSION').length >
                        0)
                      Expanded(
                          flex: allItems
                              .where((v) => v.statut == 'EN_MISSION')
                              .length,
                          child: Container(color: _kBlue)),
                    if (panne > 0)
                      Expanded(flex: panne, child: Container(color: _kRed)),
                    if (dispo +
                            allItems
                                .where((v) => v.statut == 'EN_MISSION')
                                .length +
                            panne <
                        total)
                      Expanded(
                          flex: total -
                              dispo -
                              allItems
                                  .where((v) => v.statut == 'EN_MISSION')
                                  .length -
                              panne,
                          child: Container(color: Colors.grey[200])),
                  ])),
            Divider(height: 1, color: Colors.grey[100]),
          ])),
    );
  }
}

// ── Détail type véhicule ──────────────────────────────────────────────────────
class _TypeVehiculeDetail extends StatefulWidget {
  final String typeName;
  final List<VehiculeModel> items;
  final int colorIdx;
  final bool canEdit, canDelete;
  final VoidCallback onRefresh;
  const _TypeVehiculeDetail(
      {required this.typeName,
      required this.items,
      required this.colorIdx,
      required this.canEdit,
      required this.canDelete,
      required this.onRefresh});
  @override
  State<_TypeVehiculeDetail> createState() => _TypeVehiculeDetailState();
}

class _TypeVehiculeDetailState extends State<_TypeVehiculeDetail> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  String _query = '';
  String? _statutFilter;

  List<VehiculeModel> get _filtered => widget.items.where((v) {
        final q = _query.toLowerCase();
        final match = q.isEmpty ||
            v.immatriculation.toLowerCase().contains(q) ||
            (v.marque?.toLowerCase().contains(q) ?? false) ||
            (v.conducteur.toLowerCase().contains(q));
        final statusOk = _statutFilter == null || v.statut == _statutFilter;
        return match && statusOk;
      }).toList();

  bool get _allSelected =>
      _filtered.isNotEmpty && _filtered.every((v) => _selected.contains(v.id));
  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        for (final v in _filtered) _selected.remove(v.id);
      } else {
        for (final v in _filtered) _selected.add(v.id);
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
                    child: Text(_badge(widget.typeName),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11))),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(widget.typeName,
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
                  hintText: 'Rechercher (immatriculation, marque...)',
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
                ))),
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [
                null,
                'DISPONIBLE',
                'EN_MISSION',
                'EN_PANNE',
                'EN_MAINTENANCE'
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
                                  borderRadius: BorderRadius.circular(16)),
                              child: Text(_labelStatut(s),
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
              Text('${filtered.length} engin${filtered.length > 1 ? 's' : ''}',
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
                      final v = filtered[i];
                      final isSel = _selected.contains(v.id);
                      return _VehiculeRow(
                        vehicule: v,
                        isSelected: isSel,
                        canEdit: widget.canEdit,
                        canDelete: widget.canDelete,
                        onToggle: () => setState(() {
                          if (isSel)
                            _selected.remove(v.id);
                          else
                            _selected.add(v.id);
                        }),
                        onEdit: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        VehiculeFormScreen(vehicule: v)))
                            .then((_) => widget.onRefresh()),
                        onDelete: () => context
                            .read<VehiculeProvider>()
                            .supprimerVehicule(v.id),
                      );
                    },
                  )),
      ]),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VehiculeFormScreen()));
                widget.onRefresh();
                if (mounted) setState(() {});
              },
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvel engin',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  String _labelStatut(String? s) {
    switch (s) {
      case 'DISPONIBLE':
        return 'Disponible';
      case 'EN_MISSION':
        return 'En mission';
      case 'EN_PANNE':
        return 'En panne';
      case 'EN_MAINTENANCE':
        return 'Maintenance';
      default:
        return 'Tous';
    }
  }
}

// ── Row véhicule ──────────────────────────────────────────────────────────────
class _VehiculeRow extends StatelessWidget {
  final VehiculeModel vehicule;
  final bool isSelected, canEdit, canDelete;
  final VoidCallback onToggle, onEdit, onDelete;
  const _VehiculeRow(
      {required this.vehicule,
      required this.isSelected,
      required this.canEdit,
      required this.canDelete,
      required this.onToggle,
      required this.onEdit,
      required this.onDelete});

  Color get _statusColor {
    switch (vehicule.statut) {
      case 'DISPONIBLE':
        return _kPrimary;
      case 'EN_MISSION':
        return _kBlue;
      case 'EN_PANNE':
        return _kRed;
      case 'EN_MAINTENANCE':
        return _kOrange;
      default:
        return _kGray;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(vehicule.immatriculation,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF111827))),
                const SizedBox(height: 2),
                if (vehicule.marque != null || vehicule.modele != null)
                  Text(
                      '${vehicule.marque ?? ''} ${vehicule.modele ?? ''}'
                          .trim(),
                      style: const TextStyle(fontSize: 11, color: _kGray)),
                Text('Conducteur : ${vehicule.conducteur}',
                    style: const TextStyle(fontSize: 11, color: _kGray)),
                if (vehicule.hasAlert)
                  Wrap(
                      spacing: 4,
                      children: vehicule.alertesDocs
                          .map((a) => _MiniTag(a, _kOrange))
                          .toList()),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(vehicule.statut.replaceAll('_', ' '),
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600))),
            if (vehicule.hasAlert) ...[
              const SizedBox(height: 4),
              const Icon(Icons.notifications_active, color: _kOrange, size: 16),
            ],
            if (canEdit || canDelete) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (canEdit) _ABtn(Icons.edit_outlined, _kBlue, onEdit),
                if (canDelete) ...[
                  const SizedBox(width: 4),
                  _ABtn(Icons.delete_outline, _kRed, onDelete)
                ],
              ]),
            ],
          ]),
        ]),
      );
}

// ── Tabs simples (Affectations, Incidents, Maintenances) ──────────────────────
class _SimpleList<T> extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<T> items;
  final Future<void> Function() onRefresh;
  final Widget Function(T) builder;
  final IconData emptyIcon;
  final String emptyMsg;
  const _SimpleList(
      {required this.loading,
      required this.error,
      required this.items,
      required this.onRefresh,
      required this.builder,
      required this.emptyIcon,
      required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty)
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    if (items.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(emptyIcon, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(emptyMsg, style: const TextStyle(color: _kGray)),
      ]));
    return RefreshIndicator(
        color: _kPrimary,
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: items.length,
          itemBuilder: (_, i) => builder(items[i]),
        ));
  }
}

// ── Tab Alertes ───────────────────────────────────────────────────────────────
class _AlertesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VehiculeProvider>();
    if (prov.loading && prov.alertes.isEmpty)
      return const Center(child: CircularProgressIndicator(color: _kPurple));
    if (prov.alertes.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.shield_outlined, size: 64, color: _kPrimary),
        const SizedBox(height: 12),
        const Text('Tous les documents sont à jour ✅',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)),
      ]));
    }
    return RefreshIndicator(
        color: _kPurple,
        onRefresh: () => prov.charger(refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: prov.alertes.length,
          itemBuilder: (_, i) => AlerteCard(alerte: prov.alertes[i]),
        ));
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

class _ABtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ABtn(this.icon, this.color, this.onTap);
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

class _TabInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TabInfo(this.label, this.icon, this.color);
}
