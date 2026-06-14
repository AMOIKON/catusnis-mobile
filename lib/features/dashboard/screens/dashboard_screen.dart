// lib/features/dashboard/screens/dashboard_screen.dart

import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1A56DB);
const _kGreen = Color(0xFF057A55);
const _kOrange = Color(0xFFC27803);
const _kRed = Color(0xFFC81E1E);
const _kCyan = Color(0xFF0694A2);
const _kBrown = Color(0xFF795548);
const _kGray = Color(0xFF6B7280);

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  DashboardStats _stats = DashboardStats.empty();
  List<DeploymentItem> _deployments = [];
  List<InterventionItem> _interventions = [];
  List<AcquisitionItem> _acquisitions = [];
  List<VehiculeAlerteItem> _alertesVeh = [];
  List<AcquisitionItem> _enPanne = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final isLogi = user?.role.toUpperCase().contains('LOGISTICIEN') == true;
      final isTech = user?.role.toUpperCase().contains('TECHNICIEN') == true;

      final futures = await Future.wait([
        _service.getStats(),
        _service.getRecentDeployments(),
        _service.getRecentInterventions(),
        _service.getRecentAcquisitions(),
        if (isLogi || _isAdmin(user)) _service.getVehiculeAlertes(),
        if (isTech || _isAdmin(user)) _service.getAcquisitionsEnPanne(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = futures[0] as DashboardStats;
        _deployments = futures[1] as List<DeploymentItem>;
        _interventions = futures[2] as List<InterventionItem>;
        _acquisitions = futures[3] as List<AcquisitionItem>;
        if (futures.length > 4 && futures[4] is List<VehiculeAlerteItem>) {
          _alertesVeh = futures[4] as List<VehiculeAlerteItem>;
        }
        if (futures.length > 5 && futures[5] is List<AcquisitionItem>) {
          _enPanne = futures[5] as List<AcquisitionItem>;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isAdmin(UserModel? u) =>
      u?.role.toUpperCase().contains('ADMIN') == true;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.role.toUpperCase() ?? '';

    return RefreshIndicator(
      color: _kBlue,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(user),
          const SizedBox(height: 20),
          if (role.contains('ADMIN'))
            _AdminDashboard(
              stats: _stats,
              deployments: _deployments,
              interventions: _interventions,
              acquisitions: _acquisitions,
              alertesVeh: _alertesVeh,
              enPanne: _enPanne,
              loading: _loading,
            )
          else if (role.contains('TECHNICIEN'))
            _TechnicienDashboard(
              stats: _stats,
              interventions: _interventions,
              acquisitions: _acquisitions,
              enPanne: _enPanne,
              loading: _loading,
            )
          else if (role.contains('LOGISTICIEN'))
            _LogisticienDashboard(
              stats: _stats,
              deployments: _deployments,
              alertesVeh: _alertesVeh,
              loading: _loading,
            )
          else
            _UtilisateurDashboard(stats: _stats, loading: _loading),
        ]),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    final roleLabel = _roleLabel(user?.role ?? '');
    final roleColor = _roleColor(user?.role ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBlue, _kBlue.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greet, ${user?.firstName ?? ''} 👋',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(_formatDate(DateTime.now()),
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleColor.withValues(alpha: 0.5)),
              ),
              child: Text(roleLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            user != null
                ? '${user.firstName[0]}${user.lastName[0]}'.toUpperCase()
                : '?',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD ADMIN
// ═══════════════════════════════════════════════════════════════════════════════
class _AdminDashboard extends StatelessWidget {
  final DashboardStats stats;
  final List<DeploymentItem> deployments;
  final List<InterventionItem> interventions;
  final List<AcquisitionItem> acquisitions;
  final List<VehiculeAlerteItem> alertesVeh;
  final List<AcquisitionItem> enPanne;
  final bool loading;

  const _AdminDashboard({
    required this.stats,
    required this.deployments,
    required this.interventions,
    required this.acquisitions,
    required this.alertesVeh,
    required this.enPanne,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── KPIs Équipements ──────────────────────────────────────────────────
        _SectionTitle('🏥 Équipements & Déploiements'),
        const SizedBox(height: 10),
        _KpiGrid(kpis: [
          _KpiData('Acquisitions', stats.acquisitionsTotal,
              Icons.inventory_2_outlined, _kBlue),
          _KpiData('Déploiements', stats.deploymentsTotal,
              Icons.local_shipping_outlined, _kGreen),
          _KpiData('Interventions', stats.interventionsTotal,
              Icons.build_outlined, _kOrange),
          _KpiData('Sites santé', stats.sitesTotal,
              Icons.local_hospital_outlined, _kCyan),
        ], loading: loading),
        const SizedBox(height: 12),
        _DetailBar(
          title: 'Déploiements',
          items: [
            _BarItem('Brouillon', stats.deploymentsBrouillon, _kGray),
            _BarItem('En cours', stats.deploymentsEnCours, _kBlue),
            _BarItem('Livrés', stats.deploymentsLivres, _kGreen),
          ],
          total: stats.deploymentsTotal,
          loading: loading,
        ),
        const SizedBox(height: 8),
        _DetailBar(
          title: 'Acquisitions',
          items: [
            _BarItem('Disponible', stats.acquisitionsDisponibles, _kGreen),
            _BarItem('Déployé', stats.acquisitionsDeployees, _kBlue),
            _BarItem('En panne', stats.acquisitionsEnPanne, _kRed),
          ],
          total: stats.acquisitionsTotal,
          loading: loading,
        ),
        const SizedBox(height: 20),

        // ── Vue globale (Bar chart) ───────────────────────────────────────────
        _SectionTitle('📊 Vue globale'),
        const SizedBox(height: 10),
        _GlobaleChart(stats: stats, loading: loading),
        const SizedBox(height: 20),

        // ── KPIs Logistique ───────────────────────────────────────────────────
        _SectionTitle('🚗 Logistique'),
        const SizedBox(height: 10),
        _KpiGrid(kpis: [
          _KpiData('Engins', stats.vehiculesTotal,
              Icons.directions_car_outlined, _kGreen),
          _KpiData('Fournitures', stats.fournituresTotal,
              Icons.inventory_outlined, _kBlue),
          _KpiData(
              'Archives', stats.archivesTotal, Icons.archive_outlined, _kBrown),
          _KpiData('Alertes doc.', stats.vehiculesAlertes,
              Icons.notifications_active_outlined, _kRed),
        ], loading: loading),
        const SizedBox(height: 12),
        _DetailBar(
          title: 'Parc engins',
          items: [
            _BarItem('Disponible', stats.vehiculesDisponibles, _kGreen),
            _BarItem('En mission', stats.vehiculesEnMission, _kBlue),
            _BarItem('En panne', stats.vehiculesEnPanne, _kRed),
          ],
          total: stats.vehiculesTotal,
          loading: loading,
        ),
        const SizedBox(height: 8),
        _DetailBar(
          title: 'Fournitures',
          items: [
            _BarItem('Disponible', stats.fournituresDisponibles, _kGreen),
            _BarItem('Déployé', stats.fournituresDeployees, _kBlue),
            _BarItem('Rupture', stats.fournituresEnRupture, _kRed),
          ],
          total: stats.fournituresTotal,
          loading: loading,
        ),
        const SizedBox(height: 20),

        // ── Donut statuts parc ────────────────────────────────────────────────
        _SectionTitle('🚗 Statuts du parc'),
        const SizedBox(height: 10),
        _StatutsParcChart(stats: stats, loading: loading),
        const SizedBox(height: 20),

        // ── Alertes & Activité récente ────────────────────────────────────────
        if (alertesVeh.isNotEmpty) ...[
          _SectionTitle('⚠️ Alertes documents engins'),
          const SizedBox(height: 8),
          ...alertesVeh.map((a) => _AlerteVehiculeRow(alerte: a)),
          const SizedBox(height: 20),
        ],

        if (enPanne.isNotEmpty) ...[
          _SectionTitle('🔴 Équipements en panne'),
          const SizedBox(height: 8),
          ...enPanne.map((a) => _AcqPanneRow(item: a)),
          const SizedBox(height: 20),
        ],

        _SectionTitle('📋 Déploiements récents'),
        const SizedBox(height: 8),
        _RecentDeployList(items: deployments, loading: loading),
        const SizedBox(height: 20),

        _SectionTitle('🔧 Interventions récentes'),
        const SizedBox(height: 8),
        _RecentInterList(items: interventions, loading: loading),
        const SizedBox(height: 20),

        _SectionTitle('📦 Acquisitions récentes'),
        const SizedBox(height: 8),
        _RecentAcqList(items: acquisitions, loading: loading),
      ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD TECHNICIEN
// ═══════════════════════════════════════════════════════════════════════════════
class _TechnicienDashboard extends StatelessWidget {
  final DashboardStats stats;
  final List<InterventionItem> interventions;
  final List<AcquisitionItem> acquisitions;
  final List<AcquisitionItem> enPanne;
  final bool loading;

  const _TechnicienDashboard({
    required this.stats,
    required this.interventions,
    required this.acquisitions,
    required this.enPanne,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _KpiGrid(kpis: [
          _KpiData('Interventions', stats.interventionsTotal,
              Icons.build_outlined, _kOrange),
          _KpiData('Acquisitions', stats.acquisitionsTotal,
              Icons.inventory_2_outlined, _kBlue),
          _KpiData('Déploiements', stats.deploymentsTotal,
              Icons.local_shipping_outlined, _kGreen),
          _KpiData('Sites santé', stats.sitesTotal,
              Icons.local_hospital_outlined, _kCyan),
        ], loading: loading),
        const SizedBox(height: 12),
        _DetailBar(
          title: 'Interventions',
          items: [
            _BarItem('En ligne', stats.interventionsEnLigne, _kBlue),
            _BarItem('Sur site', stats.interventionsSurSite, _kGreen),
            _BarItem('En attente', stats.interventionsEnAttente, _kOrange),
          ],
          total: stats.interventionsTotal,
          loading: loading,
        ),
        const SizedBox(height: 8),
        _DetailBar(
          title: 'Acquisitions',
          items: [
            _BarItem('Disponible', stats.acquisitionsDisponibles, _kGreen),
            _BarItem('Déployé', stats.acquisitionsDeployees, _kBlue),
            _BarItem('En panne', stats.acquisitionsEnPanne, _kRed),
          ],
          total: stats.acquisitionsTotal,
          loading: loading,
        ),
        const SizedBox(height: 20),
        _SectionTitle('📊 Vue globale'),
        const SizedBox(height: 10),
        _GlobaleChart(stats: stats, loading: loading),
        const SizedBox(height: 20),
        if (enPanne.isNotEmpty) ...[
          _SectionTitle('🔴 Équipements en panne (ma charge)'),
          const SizedBox(height: 8),
          ...enPanne.map((a) => _AcqPanneRow(item: a)),
          const SizedBox(height: 20),
        ],
        _SectionTitle('🔧 Mes interventions récentes'),
        const SizedBox(height: 8),
        _RecentInterList(items: interventions, loading: loading),
        const SizedBox(height: 20),
        _SectionTitle('📦 Acquisitions récentes'),
        const SizedBox(height: 8),
        _RecentAcqList(items: acquisitions, loading: loading),
      ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD LOGISTICIEN
// ═══════════════════════════════════════════════════════════════════════════════
class _LogisticienDashboard extends StatelessWidget {
  final DashboardStats stats;
  final List<DeploymentItem> deployments;
  final List<VehiculeAlerteItem> alertesVeh;
  final bool loading;

  const _LogisticienDashboard({
    required this.stats,
    required this.deployments,
    required this.alertesVeh,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _KpiGrid(kpis: [
          _KpiData('Engins', stats.vehiculesTotal,
              Icons.directions_car_outlined, _kGreen),
          _KpiData('Fournitures', stats.fournituresTotal,
              Icons.inventory_outlined, _kBlue),
          _KpiData('Déploiements', stats.deploymentsTotal,
              Icons.local_shipping_outlined, _kOrange),
          _KpiData('Alertes', stats.vehiculesAlertes,
              Icons.notifications_active_outlined, _kRed),
        ], loading: loading),
        const SizedBox(height: 12),
        _DetailBar(
          title: 'Parc engins',
          items: [
            _BarItem('Disponible', stats.vehiculesDisponibles, _kGreen),
            _BarItem('En mission', stats.vehiculesEnMission, _kBlue),
            _BarItem('En panne', stats.vehiculesEnPanne, _kRed),
          ],
          total: stats.vehiculesTotal,
          loading: loading,
        ),
        const SizedBox(height: 8),
        _DetailBar(
          title: 'Fournitures',
          items: [
            _BarItem('Disponible', stats.fournituresDisponibles, _kGreen),
            _BarItem('Déployé', stats.fournituresDeployees, _kBlue),
            _BarItem('Rupture', stats.fournituresEnRupture, _kRed),
          ],
          total: stats.fournituresTotal,
          loading: loading,
        ),
        const SizedBox(height: 20),
        _SectionTitle('🚗 Statuts du parc'),
        const SizedBox(height: 10),
        _StatutsParcChart(stats: stats, loading: loading),
        const SizedBox(height: 20),
        if (alertesVeh.isNotEmpty) ...[
          _SectionTitle('⚠️ Alertes documents engins'),
          const SizedBox(height: 8),
          ...alertesVeh.map((a) => _AlerteVehiculeRow(alerte: a)),
          const SizedBox(height: 20),
        ],
        if (stats.fournituresEnRupture > 0) ...[
          _RuptureAlert(count: stats.fournituresEnRupture),
          const SizedBox(height: 20),
        ],
        _SectionTitle('📋 Déploiements récents'),
        const SizedBox(height: 8),
        _RecentDeployList(items: deployments, loading: loading),
      ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD UTILISATEUR
// ═══════════════════════════════════════════════════════════════════════════════
class _UtilisateurDashboard extends StatelessWidget {
  final DashboardStats stats;
  final bool loading;
  const _UtilisateurDashboard({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: _kBlue, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Accès consultation uniquement',
                  style: TextStyle(
                      color: _kBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _KpiGrid(kpis: [
          _KpiData('Déploiements', stats.deploymentsTotal,
              Icons.local_shipping_outlined, _kGreen),
          _KpiData('Interventions', stats.interventionsTotal,
              Icons.build_outlined, _kOrange),
          _KpiData('Acquisitions', stats.acquisitionsTotal,
              Icons.inventory_2_outlined, _kBlue),
          _KpiData('Sites santé', stats.sitesTotal,
              Icons.local_hospital_outlined, _kCyan),
        ], loading: loading),
        const SizedBox(height: 12),
        _KpiGrid(kpis: [
          _KpiData('Engins', stats.vehiculesTotal,
              Icons.directions_car_outlined, _kGreen),
          _KpiData('Fournitures', stats.fournituresTotal,
              Icons.inventory_outlined, _kBlue),
          _KpiData(
              'Archives', stats.archivesTotal, Icons.archive_outlined, _kBrown),
          _KpiData('Alertes', stats.vehiculesAlertes,
              Icons.notifications_outlined, _kRed),
        ], loading: loading),
      ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ✅ NOUVEAU — Bar chart Vue globale (fl_chart)
// ═══════════════════════════════════════════════════════════════════════════════
class _GlobaleChart extends StatelessWidget {
  final DashboardStats stats;
  final bool loading;
  const _GlobaleChart({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return _LoadingChart();

    // Données : on exclut Sites car la valeur (4641) écrase les autres
    // On affiche Sites séparément comme KPI textuel
    final bars = <_BarChartItem>[
      _BarChartItem('Acq.', stats.acquisitionsTotal, _kBlue),
      _BarChartItem('Dép.', stats.deploymentsTotal, _kGreen),
      _BarChartItem('Int.', stats.interventionsTotal, _kOrange),
      _BarChartItem('Eng.', stats.vehiculesTotal, _kCyan),
      _BarChartItem('Four.', stats.fournituresTotal, _kBrown),
    ];

    final maxVal = bars.map((b) => b.value).fold(0, max).toDouble();
    final maxY = maxVal > 0 ? maxVal * 1.25 : 10.0; // ✅ 10.0 évite num

    return _Carte(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bar_chart, color: _kBlue, size: 18),
            const SizedBox(width: 6),
            const Text('Vue globale',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            // Sites en KPI séparé car valeur >> aux autres
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.local_hospital_outlined,
                    color: _kCyan, size: 12),
                const SizedBox(width: 4),
                Text('${stats.sitesTotal} sites',
                    style: const TextStyle(
                        color: _kCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: bars.asMap().entries.map((e) {
                  final item = e.value;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: item.value.toDouble(),
                        color: item.color,
                        width: 26,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length) return const SizedBox();
                        return Text(bars[i].label,
                            style:
                                const TextStyle(fontSize: 10, color: _kGray));
                      },
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${bars[group.x].label}\n${rod.toY.toInt()}',
                      TextStyle(
                          color: bars[group.x].color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ✅ NOUVEAU — Donut chart Statuts du parc (fl_chart)
// ═══════════════════════════════════════════════════════════════════════════════
class _StatutsParcChart extends StatelessWidget {
  final DashboardStats stats;
  final bool loading;
  const _StatutsParcChart({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return _LoadingChart();
    if (stats.vehiculesTotal == 0) {
      return _Carte(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('Aucun engin enregistré',
                style: const TextStyle(color: _kGray, fontSize: 13)),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[
      if (stats.vehiculesDisponibles > 0)
        PieChartSectionData(
          value: stats.vehiculesDisponibles.toDouble(),
          color: _kGreen,
          title: '${stats.vehiculesDisponibles}',
          radius: 40,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      if (stats.vehiculesEnMission > 0)
        PieChartSectionData(
          value: stats.vehiculesEnMission.toDouble(),
          color: _kBlue,
          title: '${stats.vehiculesEnMission}',
          radius: 40,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      if (stats.vehiculesEnPanne > 0)
        PieChartSectionData(
          value: stats.vehiculesEnPanne.toDouble(),
          color: _kRed,
          title: '${stats.vehiculesEnPanne}',
          radius: 40,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
    ];

    return _Carte(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Donut
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 38,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Légende
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem('Disponibles', _kGreen, stats.vehiculesDisponibles),
              const SizedBox(height: 8),
              _LegendItem('En mission', _kBlue, stats.vehiculesEnMission),
              const SizedBox(height: 8),
              _LegendItem('En panne', _kRed, stats.vehiculesEnPanne),
              const SizedBox(height: 12),
              Text('Total : ${stats.vehiculesTotal} engins',
                  style: const TextStyle(
                      fontSize: 11,
                      color: _kGray,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _LegendItem(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label : $count',
            style: const TextStyle(fontSize: 12, color: _kGray)),
      ]);
}

class _BarChartItem {
  final String label;
  final int value;
  final Color color;
  const _BarChartItem(this.label, this.value, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPOSANTS RÉUTILISABLES (inchangés sauf withOpacity → withValues)
// ═══════════════════════════════════════════════════════════════════════════════

class _KpiGrid extends StatelessWidget {
  final List<_KpiData> kpis;
  final bool loading;
  const _KpiGrid({required this.kpis, required this.loading});

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55, // ✅ plus de hauteur
        ),
        itemCount: kpis.length,
        itemBuilder: (_, i) => _KpiCard(kpi: kpis[i], loading: loading),
      );
}

class _KpiCard extends StatelessWidget {
  final _KpiData kpi;
  final bool loading;
  const _KpiCard({required this.kpi, required this.loading});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(children: [
            Container(
              width: 36, height: 36, // ✅ réduit de 42 à 36
              decoration: BoxDecoration(
                color: kpi.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(kpi.icon, color: kpi.color, size: 18), // ✅ 22→18
            ),
            const SizedBox(width: 8), // ✅ 12→8
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  loading
                      ? Container(
                          width: 36,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ))
                      : Text('${kpi.value}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // ✅ ajouté
                          style: TextStyle(
                              fontSize: 18, // ✅ 22→18
                              fontWeight: FontWeight.bold,
                              color: kpi.color)),
                  const SizedBox(height: 2),
                  Text(kpi.label,
                      style: const TextStyle(
                          fontSize: 10, color: _kGray), // ✅ 11→10
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),
      );
}

class _DetailBar extends StatelessWidget {
  final String title;
  final List<_BarItem> items;
  final int total;
  final bool loading;
  const _DetailBar({
    required this.title,
    required this.items,
    required this.total,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) => _Carte(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF111827))),
              ),
              if (!loading)
                Text('$total total',
                    style: const TextStyle(fontSize: 11, color: _kGray)),
            ]),
          ),
          const SizedBox(height: 10),
          if (loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          else if (total > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: items.map((item) {
                      final int flex = item.count > 0 ? item.count : 0;
                      return flex > 0
                          ? Expanded(
                              flex: flex, child: Container(color: item.color))
                          : const SizedBox.shrink();
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: items
                    .map((item) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: item.color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('${item.label} : ${item.count}',
                                style: const TextStyle(
                                    fontSize: 11, color: _kGray)),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text('Aucune donnée',
                  style: TextStyle(fontSize: 11, color: _kGray)),
            ),
        ]),
      );
}

class _RecentDeployList extends StatelessWidget {
  final List<DeploymentItem> items;
  final bool loading;
  const _RecentDeployList({required this.items, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return _LoadingList();
    if (items.isEmpty) return const _EmptyMsg('Aucun déploiement récent');
    return _Carte(
      child: Column(
        children: items.asMap().entries.map((e) {
          final d = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            _RecentRow(
              icon: Icons.local_shipping_outlined,
              color: _kGreen,
              title: d.codeDep,
              subtitle: d.healthName ?? d.regionName ?? '—',
              trailing: _statutBadge(d.statut),
              date: d.dateRecept,
            ),
            if (!isLast) Divider(height: 1, color: Colors.grey[100]),
          ]);
        }).toList(),
      ),
    );
  }
}

class _RecentInterList extends StatelessWidget {
  final List<InterventionItem> items;
  final bool loading;
  const _RecentInterList({required this.items, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return _LoadingList();
    if (items.isEmpty) return const _EmptyMsg('Aucune intervention récente');
    return _Carte(
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.value;
          final isLast = e.key == items.length - 1;
          final color = i.typeInter == 'EN_LIGNE' ? _kBlue : _kGreen;
          final icon = i.typeInter == 'EN_LIGNE'
              ? Icons.wifi_outlined
              : Icons.location_on_outlined;
          return Column(children: [
            _RecentRow(
              icon: icon,
              color: color,
              title: i.codeInter,
              subtitle: i.actionInter ?? i.healthName ?? '—',
              trailing: i.enAttenteMaintenance
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Attente',
                          style: TextStyle(
                              color: _kRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)))
                  : null,
              date: i.dateIntervention,
            ),
            if (!isLast) Divider(height: 1, color: Colors.grey[100]),
          ]);
        }).toList(),
      ),
    );
  }
}

class _RecentAcqList extends StatelessWidget {
  final List<AcquisitionItem> items;
  final bool loading;
  const _RecentAcqList({required this.items, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return _LoadingList();
    if (items.isEmpty) return const _EmptyMsg('Aucune acquisition récente');
    return _Carte(
      child: Column(
        children: items.asMap().entries.map((e) {
          final a = e.value;
          final isLast = e.key == items.length - 1;
          final statusColor = a.status == 'EN_PANNE'
              ? _kRed
              : a.status == 'DISPONIBLE'
                  ? _kGreen
                  : _kBlue;
          return Column(children: [
            _RecentRow(
              icon: Icons.inventory_2_outlined,
              color: _kBlue,
              title: a.tag ?? a.serial ?? 'N/A',
              subtitle: a.typeName ?? '—',
              trailing: a.status != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(a.status!,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)))
                  : null,
              date: a.dateAcq,
            ),
            if (!isLast) Divider(height: 1, color: Colors.grey[100]),
          ]);
        }).toList(),
      ),
    );
  }
}

class _AlerteVehiculeRow extends StatelessWidget {
  final VehiculeAlerteItem alerte;
  const _AlerteVehiculeRow({required this.alerte});

  @override
  Widget build(BuildContext context) {
    final color = alerte.isExpire ? _kRed : _kOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(
            alerte.isExpire ? Icons.error_outline : Icons.access_time_outlined,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alerte.immatriculation,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(alerte.typeAlerte.replaceAll('_', ' '),
                style: TextStyle(fontSize: 11, color: color)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(
            alerte.isExpire ? 'EXPIRÉ' : '${alerte.joursRestants}j',
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }
}

class _AcqPanneRow extends StatelessWidget {
  final AcquisitionItem item;
  const _AcqPanneRow({required this.item});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRed.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, color: _kRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.tag ?? item.serial ?? 'N/A',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(item.typeName ?? '—',
                  style: const TextStyle(fontSize: 11, color: _kGray)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('EN PANNE',
                style: TextStyle(
                    color: _kRed, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
      );
}

class _RuptureAlert extends StatelessWidget {
  final int count;
  const _RuptureAlert({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kRed.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kRed.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_outlined, color: _kRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Articles en rupture de stock',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: _kRed, fontSize: 13)),
              Text(
                '$count article${count > 1 ? 's' : ''} nécessitent un réapprovisionnement',
                style: const TextStyle(fontSize: 11, color: _kGray),
              ),
            ]),
          ),
        ]),
      );
}

class _RecentRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? date;

  const _RecentRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.date,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: _kGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ] else if (date != null)
            Text(_formatDateShort(date),
                style: const TextStyle(fontSize: 10, color: _kGray)),
        ]),
      );
}

class _Carte extends StatelessWidget {
  final Widget child;
  const _Carte({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)));
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Carte(
        child: Column(
          children: List.generate(
              3,
              (i) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: 120,
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ]),
                      ),
                    ]),
                  )),
        ),
      );
}

class _LoadingChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Carte(
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(
              height: 12,
              width: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                    5,
                    (i) => Container(
                          width: 26,
                          height: 40.0 + (i * 15),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        )),
              ),
            ),
          ]),
        ),
      );
}

class _EmptyMsg extends StatelessWidget {
  final String msg;
  const _EmptyMsg(this.msg);

  @override
  Widget build(BuildContext context) => _Carte(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child:
                Text(msg, style: const TextStyle(color: _kGray, fontSize: 13)),
          ),
        ),
      );
}

// ── Data classes ──────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}

class _BarItem {
  final String label;
  final int count;
  final Color color;
  const _BarItem(this.label, this.count, this.color);
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _statutBadge(String statut) {
  Color color;
  switch (statut) {
    case 'BROUILLON':
      color = _kGray;
      break;
    case 'EN_COURS':
      color = _kBlue;
      break;
    case 'LIVRE':
      color = _kGreen;
      break;
    case 'ARCHIVE':
      color = _kBrown;
      break;
    case 'ANNULE':
      color = _kRed;
      break;
    default:
      color = _kGray;
  }
  final labels = {
    'BROUILLON': 'Brouillon',
    'EN_COURS': 'En cours',
    'LIVRE': 'Livré',
    'ARCHIVE': 'Archivé',
    'ANNULE': 'Annulé',
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(labels[statut] ?? statut,
        style:
            TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
  );
}

String _roleLabel(String role) {
  switch (role.toUpperCase()) {
    case 'SUPER_ADMIN':
      return '⭐ Super Admin';
    case 'ADMIN':
      return '🔑 Admin';
    case 'TECHNICIEN':
      return '🔧 Technicien';
    case 'LOGISTICIEN':
      return '🚗 Logisticien';
    default:
      return '👁 Utilisateur';
  }
}

Color _roleColor(String role) {
  switch (role.toUpperCase()) {
    case 'SUPER_ADMIN':
      return Colors.amber;
    case 'ADMIN':
      return Colors.orange;
    case 'TECHNICIEN':
      return Colors.green;
    case 'LOGISTICIEN':
      return Colors.teal;
    default:
      return Colors.blue;
  }
}

String _formatDate(DateTime d) {
  const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  const months = [
    '',
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Jun',
    'Jul',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc'
  ];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month]} ${d.year}';
}

String _formatDateShort(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso;
  }
}
