// lib/features/technician_sites/screens/technician_site_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/technician_site_provider.dart';
import '../widgets/region_tree_card.dart';
import '../../persons/models/person.dart';
import '../../persons/services/person_service.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1D4ED8);
const _kGreen = Color(0xFF15803D);
const _kGray = Color(0xFF6B7280);

class TechnicianSiteScreen extends StatefulWidget {
  const TechnicianSiteScreen({super.key});
  @override
  State<TechnicianSiteScreen> createState() => _TechnicianSiteScreenState();
}

class _TechnicianSiteScreenState extends State<TechnicianSiteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PersonService _personService = PersonService();

  List<Person> _techniciens = [];
  List<Person> _logisticiens = [];
  bool _personsLoading = true;

  Person? _selectedTech;
  Person? _selectedLogi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<TechnicianSiteProvider>().clearForPerson();
      }
    });
    _loadPersons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPersons() async {
    setState(() => _personsLoading = true);
    try {
      final all = await _personService.getAllList();
      setState(() {
        _techniciens = all
            .where((p) => (p.role?.toUpperCase() ?? '').contains('TECHNICIEN'))
            .toList();
        _logisticiens = all
            .where((p) => (p.role?.toUpperCase() ?? '').contains('LOGISTICIEN'))
            .toList();
        _personsLoading = false;
      });
    } catch (_) {
      setState(() => _personsLoading = false);
    }
  }

  void _selectPerson(Person p, bool isTechTab) {
    setState(() {
      if (isTechTab)
        _selectedTech = p;
      else
        _selectedLogi = p;
    });
    context.read<TechnicianSiteProvider>().loadByPerson(p.id);
  }

  bool get _canManage {
    final user = context.read<AuthProvider>().user;
    return user?.isSuperAdmin == true || user?.isAdmin == true;
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retirer le site'),
        content: const Text('Supprimer cette assignation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success = await context.read<TechnicianSiteProvider>().unassign(id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur suppression'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddSheet(Person person, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAssignSheet(
        person: person,
        color: color,
        provider: context.read<TechnicianSiteProvider>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // ── Header gradient ───────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(children: [
                // Titre + badge admin
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sites attribués',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Périmètre géographique',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.shield_outlined,
                          color: Colors.amber, size: 12),
                      SizedBox(width: 4),
                      Text('Admin global',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),

                // Onglets
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                          icon: Icon(Icons.engineering, size: 16),
                          text: 'Techniciens'),
                      Tab(
                          icon: Icon(Icons.local_shipping_outlined, size: 16),
                          text: 'Logisticiens'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ),

        // ── Corps ─────────────────────────────────────────────────────────
        Expanded(
          child: _personsLoading
              ? const Center(child: CircularProgressIndicator(color: _kBlue))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _PersonSplit(
                      persons: _techniciens,
                      selected: _selectedTech,
                      onSelect: (p) => _selectPerson(p, true),
                      accentColor: _kBlue,
                      canManage: _canManage,
                      onDelete: _confirmDelete,
                      onAdd: (p) => _showAddSheet(p, _kBlue),
                    ),
                    _PersonSplit(
                      persons: _logisticiens,
                      selected: _selectedLogi,
                      onSelect: (p) => _selectPerson(p, false),
                      accentColor: _kGreen,
                      canManage: _canManage,
                      onDelete: _confirmDelete,
                      onAdd: (p) => _showAddSheet(p, _kGreen),
                    ),
                  ],
                ),
        ),
      ]),

      // ✅ FAB Assigner — toujours visible si admin
      if (_canManage)
        Positioned(
          bottom: 24,
          right: 16,
          child: GestureDetector(
            onTap: () {
              final isTech = _tabController.index == 0;
              final person = isTech ? _selectedTech : _selectedLogi;
              final color = isTech ? _kBlue : _kGreen;
              if (person != null) {
                _showAddSheet(person, color);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Sélectionnez un collaborateur dans la liste'),
                    backgroundColor: color,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: _tabController.index == 0 ? _kBlue : _kGreen,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_location_alt_outlined,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Assigner',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Vue split personne + périmètre
// ═══════════════════════════════════════════════════════════════════════════════
class _PersonSplit extends StatelessWidget {
  final List<Person> persons;
  final Person? selected;
  final void Function(Person) onSelect;
  final Color accentColor;
  final bool canManage;
  final void Function(int) onDelete;
  final void Function(Person) onAdd;

  const _PersonSplit({
    required this.persons,
    required this.selected,
    required this.onSelect,
    required this.accentColor,
    required this.canManage,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.group_off_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Aucun collaborateur trouvé',
              style: TextStyle(color: _kGray)),
        ]),
      );
    }

    return Column(children: [
      // ── Liste personnes ───────────────────────────────────────────────────
      Container(
        color: Colors.white,
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: persons.length,
          itemBuilder: (_, i) {
            final p = persons[i];
            final isSelected = selected?.id == p.id;
            final initials =
                '${p.firstName.isNotEmpty ? p.firstName[0] : ''}${p.lastName.isNotEmpty ? p.lastName[0] : ''}'
                    .toUpperCase();

            return GestureDetector(
              onTap: () => onSelect(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : accentColor.withValues(alpha: 0.12),
                    child: Text(initials,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : accentColor,
                        )),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.firstName} ${p.lastName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF111827),
                          )),
                      if (p.postName?.isNotEmpty == true)
                        Text(p.postName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : _kGray,
                            )),
                    ],
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      const Divider(height: 1),

      // ── Périmètre ─────────────────────────────────────────────────────────
      Expanded(
        child: selected == null
            ? _EmptyState(accentColor: accentColor)
            : _PerimetreView(
                person: selected!,
                canManage: canManage,
                onDelete: onDelete,
                accentColor: accentColor,
                onAdd: () => onAdd(selected!),
              ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Vue périmètre
// ═══════════════════════════════════════════════════════════════════════════════
class _PerimetreView extends StatelessWidget {
  final Person person;
  final bool canManage;
  final void Function(int) onDelete;
  final Color accentColor;
  final VoidCallback onAdd;

  const _PerimetreView({
    required this.person,
    required this.canManage,
    required this.onDelete,
    required this.accentColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechnicianSiteProvider>();

    if (provider.status == TechnicianSiteStatus.loading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (provider.status == TechnicianSiteStatus.error) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 8),
        Text(provider.error ?? 'Erreur',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: provider.refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(backgroundColor: accentColor),
        ),
      ]));
    }

    return CustomScrollView(
      slivers: [
        // ── Header personne ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  '${person.firstName.isNotEmpty ? person.firstName[0] : ''}${person.lastName.isNotEmpty ? person.lastName[0] : ''}'
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${person.firstName} ${person.lastName}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    if (person.postName?.isNotEmpty == true)
                      Text(person.postName!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              // ✅ Bouton ajouter
              if (canManage)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, color: accentColor, size: 14),
                      const SizedBox(width: 4),
                      Text('Assigner',
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
          ),
        ),

        // ── KPIs ────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: [
              _KpiCard(
                count: provider.totalRegions,
                label: 'Régions',
                icon: Icons.public_outlined,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _KpiCard(
                count: provider.totalDistricts,
                label: 'Districts',
                icon: Icons.location_city_outlined,
                color: Colors.cyan[700]!,
              ),
              const SizedBox(width: 8),
              _KpiCard(
                count: provider.totalSites,
                label: 'Sites',
                icon: Icons.local_hospital_outlined,
                color: Colors.green[700]!,
              ),
            ]),
          ),
        ),

        // ── Liste assignations ───────────────────────────────────────────────
        if (provider.assignments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.map_outlined,
                      size: 36, color: accentColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                const Text('Aucun site assigné',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF111827))),
                const SizedBox(height: 6),
                const Text('Appuyez sur "Assigner" pour ajouter',
                    style: TextStyle(color: _kGray, fontSize: 12)),
              ]),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final nodes = provider.tree;
                if (i >= nodes.length) return null;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: RegionTreeCard(
                    region: nodes[i],
                    canManage: canManage,
                    onDelete: onDelete,
                    onEdit: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Utilisez l\'interface web pour modifier'),
                        duration: Duration(seconds: 2),
                      ),
                    ),
                  ),
                );
              },
              childCount: provider.tree.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom sheet ajout d'assignation
// ═══════════════════════════════════════════════════════════════════════════════
class _AddAssignSheet extends StatefulWidget {
  final Person person;
  final Color color;
  final TechnicianSiteProvider provider;

  const _AddAssignSheet({
    required this.person,
    required this.color,
    required this.provider,
  });

  @override
  State<_AddAssignSheet> createState() => _AddAssignSheetState();
}

class _AddAssignSheetState extends State<_AddAssignSheet> {
  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.add_location_alt_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Assigner un site',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Text('${widget.person.firstName} ${widget.person.lastName}',
                  style: const TextStyle(fontSize: 12, color: _kGray)),
            ]),
          ]),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'L\'assignation se fait via l\'interface web CATUSNIS. '
                  'Utilisez le bouton ci-dessous pour ouvrir la gestion complète.',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    const Icon(Icons.open_in_new,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connectez-vous à l\'interface web pour assigner '
                        '${widget.person.firstName} à un périmètre.',
                      ),
                    ),
                  ]),
                  backgroundColor: color,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              icon: const Icon(Icons.language, color: Colors.white),
              label: const Text('Gérer via l\'interface web',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Actualiser
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.provider.loadByPerson(widget.person.id);
              },
              icon: Icon(Icons.refresh, color: color),
              label: Text('Actualiser les assignations',
                  style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI card
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text('$count',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: _kGray)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Color accentColor;
  const _EmptyState({required this.accentColor});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.person_search_outlined,
                size: 44, color: accentColor.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('Sélectionnez un collaborateur',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text('Les sites attribués s\'afficheront ici',
              style: TextStyle(color: _kGray, fontSize: 12)),
        ]),
      );
}
