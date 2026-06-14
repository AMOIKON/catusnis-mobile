// lib/features/fournitures/screens/fourniture_screen.dart
// ✅ FournitureDeploiementFormScreen inclus directement — plus d'import séparé

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/fourniture_model.dart';
import '../providers/fourniture_provider.dart';
import '../services/fourniture_service.dart';
import 'fourniture_form_screen.dart';

// ── Couleurs ──────────────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1565C0);
const _kGreen = Color(0xFF2E7D52);
const _kOrange = Color(0xFFFF6F00);
const _kRed = Color(0xFFC62828);
const _kGray = Color(0xFF6B7280);
const _kBg = Color(0xFFF0F4FF);

// ── Classes config (sans records Dart 3) ─────────────────────────────────────
class _CatInfo {
  final IconData icon;
  final Color color;
  final String label;
  const _CatInfo(this.icon, this.color, this.label);
}

class _StatutInfo {
  final Color color;
  final String label;
  const _StatutInfo(this.color, this.label);
}

const _catConfig = <String, _CatInfo>{
  'INFORMATIQUE':
      _CatInfo(Icons.computer_outlined, Color(0xFF1565C0), 'Informatique'),
  'MOBILIER': _CatInfo(Icons.chair_outlined, Color(0xFF2E7D52), 'Mobilier'),
  'PAPETERIE':
      _CatInfo(Icons.description_outlined, Color(0xFFF57C00), 'Papeterie'),
  'BUREAUTIQUE':
      _CatInfo(Icons.print_outlined, Color(0xFF0694A2), 'Bureautique'),
  'ELECTROMENAGER': _CatInfo(
      Icons.electrical_services_outlined, Color(0xFFC62828), 'Électroménager'),
  'AUTRE': _CatInfo(Icons.category_outlined, Color(0xFF6B7280), 'Autre'),
};

const _statutConfig = <String, _StatutInfo>{
  'DISPONIBLE': _StatutInfo(Color(0xFF2E7D52), 'Disponible'),
  'DEPLOYE': _StatutInfo(Color(0xFF1565C0), 'Déployé'),
  'EN_RUPTURE': _StatutInfo(Color(0xFFC62828), 'En rupture'),
};

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL FOURNITURES
// ═══════════════════════════════════════════════════════════════════════════════
class FournitureScreen extends StatefulWidget {
  const FournitureScreen({super.key});
  @override
  State<FournitureScreen> createState() => _FournitureScreenState();
}

class _FournitureScreenState extends State<FournitureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<FournitureProvider>().setTab(_tabCtrl.index);
        _searchCtrl.clear();
        setState(() => _searchActive = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FournitureProvider>().charger(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<FournitureProvider>().charger();
    }
  }

  bool _canEdit(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('ADMIN') || role.contains('LOGISTICIEN');
  }

  bool _canDelete(BuildContext ctx) =>
      (context.read<AuthProvider>().user?.role ?? '')
          .toUpperCase()
          .contains('ADMIN');

  bool _canDeploy(BuildContext ctx) {
    final role = (ctx.read<AuthProvider>().user?.role ?? '').toUpperCase();
    return role.contains('ADMIN') ||
        role.contains('LOGISTICIEN') ||
        role.contains('TECHNICIEN');
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FournitureProvider>();
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        _buildHeader(prov),
        _buildStatsRow(prov.stats),
        if (_searchActive)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => prov.setKeyword(v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'Rechercher par code, désignation...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _searchActive = false);
                    _searchCtrl.clear();
                    prov.setKeyword(null);
                  },
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: _kBlue,
            labelColor: _kBlue,
            unselectedLabelColor: _kGray,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Articles (${prov.total})'),
              Tab(text: 'Déploiements (${prov.deploiements.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ArticlesList(
                  scrollCtrl: _scrollCtrl,
                  canEdit: _canEdit(context),
                  canDelete: _canDelete(context),
                  canDeploy: _canDeploy(context)),
              _DeploiementsList(
                  canEdit: _canEdit(context), canDelete: _canDelete(context)),
            ],
          ),
        ),
      ]),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(FournitureProvider prov) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [_kBlue, Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Fournitures & Mobilier',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${prov.total} article(s) enregistré(s)',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ])),
          if (prov.stats.enRupture > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${prov.stats.enRupture} en rupture',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_searchActive ? Icons.search_off : Icons.search,
                color: Colors.white),
            onPressed: () => setState(() => _searchActive = !_searchActive),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => prov.charger(refresh: true),
            padding: EdgeInsets.zero,
          ),
        ]),
      );

  Widget _buildStatsRow(FournitureStats s) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatPill('${s.disponibles}', 'Dispo', _kGreen),
          _StatPill('${s.deployes}', 'Déployé', _kBlue),
          _StatPill('${s.enRupture}', 'Rupture', _kRed),
          _StatPill('${s.totalDeploiements}', 'Dép. actifs', _kOrange),
        ]),
      );

  Widget? _buildFab(BuildContext context) {
    if (!_canEdit(context)) return null;
    if (_tabCtrl.index == 0) {
      return FloatingActionButton.extended(
        backgroundColor: _kBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvel article',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FournitureFormScreen()))
            .then((_) =>
                context.read<FournitureProvider>().charger(refresh: true)),
      );
    }
    if (_tabCtrl.index == 1 && _canDeploy(context)) {
      return FloatingActionButton.extended(
        backgroundColor: _kGreen,
        icon: const Icon(Icons.send_outlined, color: Colors.white),
        label: const Text('Déployer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => FournitureDeploiementFormScreen())).then(
            (_) => context.read<FournitureProvider>().charger(refresh: true)),
      );
    }
    return null;
  }
}

// ── Liste Articles ────────────────────────────────────────────────────────────
class _ArticlesList extends StatelessWidget {
  final ScrollController scrollCtrl;
  final bool canEdit, canDelete, canDeploy;
  const _ArticlesList(
      {required this.scrollCtrl,
      required this.canEdit,
      required this.canDelete,
      required this.canDeploy});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FournitureProvider>();
    if (prov.loading && prov.fournitures.isEmpty)
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    if (prov.error != null && prov.fournitures.isEmpty) {
      return NetworkErrorWidget(
          message: prov.error!,
          onRetry: () =>
              context.read<FournitureProvider>().charger(refresh: true));
    }
    if (prov.fournitures.isEmpty)
      return const Center(
          child: Text('Aucun article enregistré',
              style: TextStyle(color: _kGray)));
    return RefreshIndicator(
      color: _kBlue,
      onRefresh: () =>
          context.read<FournitureProvider>().charger(refresh: true),
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: prov.fournitures.length + (prov.loading ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= prov.fournitures.length) {
            return const Padding(
                padding: EdgeInsets.all(16),
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }
          return _FournitureCard(
            item: prov.fournitures[i],
            canEdit: canEdit,
            canDelete: canDelete,
            canDeploy: canDeploy,
            onEdit: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => FournitureFormScreen(
                        fourniture: prov.fournitures[i]))).then(
                (_) => ctx.read<FournitureProvider>().charger(refresh: true)),
            onDelete: () => ctx
                .read<FournitureProvider>()
                .supprimerFourniture(prov.fournitures[i].id),
            onDeploy: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => FournitureDeploiementFormScreen(
                        fourniture: prov.fournitures[i]))).then(
                (_) => ctx.read<FournitureProvider>().charger(refresh: true)),
          );
        },
      ),
    );
  }
}

// ── Liste Déploiements ────────────────────────────────────────────────────────
class _DeploiementsList extends StatelessWidget {
  final bool canEdit, canDelete;
  const _DeploiementsList({required this.canEdit, required this.canDelete});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FournitureProvider>();
    if (prov.loading && prov.deploiements.isEmpty)
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    if (prov.deploiements.isEmpty)
      return const Center(
          child: Text('Aucun déploiement', style: TextStyle(color: _kGray)));
    return RefreshIndicator(
      color: _kGreen,
      onRefresh: () =>
          context.read<FournitureProvider>().charger(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: prov.deploiements.length,
        itemBuilder: (ctx, i) => _DeploiementCard(
          item: prov.deploiements[i],
          canEdit: canEdit,
          canDelete: canDelete,
          onCloturer: () => ctx
              .read<FournitureProvider>()
              .cloturerDeploiement(prov.deploiements[i].id),
        ),
      ),
    );
  }
}

// ── Card Article ──────────────────────────────────────────────────────────────
class _FournitureCard extends StatelessWidget {
  final FournitureModel item;
  final bool canEdit, canDelete, canDeploy;
  final VoidCallback onEdit, onDelete, onDeploy;
  const _FournitureCard(
      {required this.item,
      required this.canEdit,
      required this.canDelete,
      required this.canDeploy,
      required this.onEdit,
      required this.onDelete,
      required this.onDeploy});

  @override
  Widget build(BuildContext context) {
    final cat = _catConfig[item.categorie] ?? _catConfig['AUTRE']!;
    final statut =
        _statutConfig[item.statut] ?? const _StatutInfo(_kGray, 'Inconnu');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(cat.icon, color: cat.color, size: 22)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.designation,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(item.code,
                      style: const TextStyle(
                          color: _kBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statut.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statut.label,
                  style: TextStyle(
                      color: statut.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Qty('Total', item.quantite, _kGray),
            const SizedBox(width: 12),
            _Qty('Dispo', item.quantiteDisponible, _kGreen),
            const SizedBox(width: 12),
            _Qty('Déployé', item.quantiteDeployee, _kBlue),
            const Spacer(),
            if (item.unite != null)
              Text(item.unite!,
                  style: const TextStyle(color: _kGray, fontSize: 11)),
          ]),
          if (canEdit ||
              canDelete ||
              (canDeploy && item.quantiteDisponible > 0)) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (canDeploy && item.quantiteDisponible > 0) ...[
                _Btn(Icons.send_outlined, 'Déployer', _kGreen, onDeploy),
                const SizedBox(width: 6),
              ],
              if (canEdit) ...[
                _Btn(Icons.edit_outlined, 'Modifier', _kBlue, onEdit),
                const SizedBox(width: 6),
              ],
              if (canDelete)
                _Btn(Icons.delete_outline, 'Supprimer', _kRed, onDelete),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── Card Déploiement ──────────────────────────────────────────────────────────
class _DeploiementCard extends StatelessWidget {
  final FournitureDeploiementModel item;
  final bool canEdit, canDelete;
  final VoidCallback onCloturer;
  const _DeploiementCard(
      {required this.item,
      required this.canEdit,
      required this.canDelete,
      required this.onCloturer});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
                radius: 22,
                backgroundColor: _kGreen.withOpacity(0.1),
                child: Text('${item.quantiteDeployee}',
                    style: const TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.fournitureDesignation,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(item.fournitureCode,
                      style: const TextStyle(color: _kBlue, fontSize: 11)),
                  if (item.beneficiaireNom != null)
                    Text('→ ${item.beneficiaireNom}',
                        style: const TextStyle(color: _kGray, fontSize: 12)),
                  if (item.regionName != null)
                    Text(item.regionName!,
                        style: const TextStyle(color: _kGray, fontSize: 11)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: (item.active ? _kGreen : _kGray).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(item.active ? 'Actif' : 'Clôturé',
                    style: TextStyle(
                        color: item.active ? _kGreen : _kGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              if (item.active && canEdit) ...[
                const SizedBox(height: 6),
                InkWell(
                    onTap: onCloturer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: _kOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('Clôturer',
                          style: TextStyle(
                              color: _kOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    )),
              ],
            ]),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORMULAIRE DÉPLOIEMENT FOURNITURE (inclus ici — plus d'import séparé)
// ═══════════════════════════════════════════════════════════════════════════════
class FournitureDeploiementFormScreen extends StatefulWidget {
  final FournitureModel? fourniture;
  const FournitureDeploiementFormScreen({super.key, this.fourniture});

  @override
  State<FournitureDeploiementFormScreen> createState() =>
      _FournitureDeploiementFormState();
}

class _FournitureDeploiementFormState
    extends State<FournitureDeploiementFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = FournitureService();
  bool _saving = false;

  late TextEditingController _benomCtrl;
  late TextEditingController _beposteCtrl;
  late TextEditingController _qteCtrl;
  late TextEditingController _motifCtrl;

  @override
  void initState() {
    super.initState();
    _benomCtrl = TextEditingController();
    _beposteCtrl = TextEditingController();
    _qteCtrl = TextEditingController(text: '1');
    _motifCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _benomCtrl.dispose();
    _beposteCtrl.dispose();
    _qteCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.fourniture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez un article d\'abord')));
      return;
    }
    setState(() => _saving = true);
    final body = {
      'fournitureId': widget.fourniture!.id,
      'beneficiaireNom': _benomCtrl.text.trim(),
      'beneficiairePoste': _beposteCtrl.text.trim(),
      'quantiteDeployee': int.tryParse(_qteCtrl.text.trim()) ?? 1,
      'motif': _motifCtrl.text.trim(),
      'dateDeploiement': DateTime.now().toIso8601String().split('T')[0],
    };
    try {
      await _svc.createDeploiement(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D52),
          foregroundColor: Colors.white,
          title: const Text('Déployer une fourniture'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.fourniture != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D52).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF2E7D52).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF2E7D52)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(widget.fourniture!.designation,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Disponible : ${widget.fourniture!.quantiteDisponible}'
                            '${widget.fourniture!.unite != null ? ' ${widget.fourniture!.unite}' : ''}',
                            style: const TextStyle(
                                color: Color(0xFF2E7D52), fontSize: 12),
                          ),
                        ])),
                  ]),
                ),
              _FormField(
                  ctrl: _benomCtrl,
                  label: 'Nom bénéficiaire',
                  icon: Icons.person_outline),
              const SizedBox(height: 14),
              _FormField(
                  ctrl: _beposteCtrl,
                  label: 'Poste / Fonction',
                  icon: Icons.work_outline),
              const SizedBox(height: 14),
              _FormField(
                ctrl: _qteCtrl,
                label: 'Quantité à déployer *',
                icon: Icons.numbers_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Quantité invalide';
                  if (widget.fourniture != null &&
                      n > widget.fourniture!.quantiteDisponible) {
                    return 'Insuffisant (dispo: ${widget.fourniture!.quantiteDisponible})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FormField(
                  ctrl: _motifCtrl,
                  label: 'Motif / Destination',
                  icon: Icons.notes_outlined,
                  maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmer le déploiement',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Qty extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Qty(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text('$value',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: _kGray, fontSize: 10)),
      ]);
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatPill(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: _kGray, fontSize: 10)),
      ]);
}

// ✅ Renommé _FormField pour éviter tout conflit avec _Field d'autres fichiers
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  const _FormField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        ),
      );
}
