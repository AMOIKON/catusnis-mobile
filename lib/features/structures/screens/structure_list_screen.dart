// lib/features/structures/screens/structure_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/notify.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/structure_model.dart';
import '../providers/structure_provider.dart';
import 'structure_form_screen.dart';

const _kPrimary = Color(0xFF0F4C81);
const _kRed = Color(0xFFC81E1E);
const _kGray = Color(0xFF607D8B);
const _kBg = Color(0xFFF0F4F8);

class StructureListScreen extends StatefulWidget {
  const StructureListScreen({super.key});
  @override
  State<StructureListScreen> createState() => _StructureListScreenState();
}

class _StructureListScreenState extends State<StructureListScreen> {
  final _searchCtrl = TextEditingController();

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
      context.read<StructureListProvider>().charger(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmerSuppression(StructureModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la structure'),
        content: Text(
            'Voulez-vous vraiment supprimer "${s.nom}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer', style: TextStyle(color: _kRed))),
        ],
      ),
    );
    if (confirm != true) return;

    final prov = context.read<StructureListProvider>();
    final ok = await prov.supprimer(s.id);
    if (!mounted) return;

    if (ok) {
      Notify.success(context, 'Structure supprimée avec succès');
    } else {
      Notify.error(
        context,
        prov.errorMessage ?? 'Erreur lors de la suppression de la structure',
      );
    }
  }

  void _ouvrirFormulaire(StructureModel? s) async {
    final prov = context.read<StructureListProvider>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StructureFormScreen(structure: s)),
    );
    if (result is StructureModel) {
      prov.charger(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StructureListProvider>();
    final canEdit = _canEdit(context);
    final canDelete = _canDelete(context);

    if (prov.hasError && prov.items.isEmpty) {
      return NetworkErrorWidget(onRetry: () => prov.charger(refresh: true));
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        // ── Header KPI ─────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.account_balance_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Text('${prov.totalElements} structure(s) enregistrée(s)',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),

        // ── Recherche ──────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => prov.setKeyword(v),
            decoration: InputDecoration(
              hintText: 'Rechercher une structure...',
              prefixIcon: const Icon(Icons.search, color: _kGray, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: _kGray,
                      onPressed: () {
                        _searchCtrl.clear();
                        prov.setKeyword(null);
                      })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),

        // ── Liste ──────────────────────────────────────────────────────────
        Expanded(
          child: prov.isLoading && prov.items.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : prov.items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: () => prov.charger(refresh: true),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: prov.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final s = prov.items[i];
                          return _StructureCard(
                            structure: s,
                            canEdit: canEdit,
                            canDelete: canDelete,
                            onEdit: () => _ouvrirFormulaire(s),
                            onDelete: () => _confirmerSuppression(s),
                          );
                        },
                      ),
                    ),
        ),
      ]),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _ouvrirFormulaire(null),
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
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
              child: const Icon(Icons.account_balance_outlined,
                  color: _kPrimary, size: 40)),
          const SizedBox(height: 16),
          const Text('Aucune structure étatique',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Les structures apparaîtront ici',
              style: TextStyle(color: _kGray)),
        ]),
      );
}

// ── Carte structure ───────────────────────────────────────────────────────────
class _StructureCard extends StatelessWidget {
  final StructureModel structure;
  final bool canEdit, canDelete;
  final VoidCallback onEdit, onDelete;

  const _StructureCard({
    required this.structure,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: _kPrimary, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(structure.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14))),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(structure.nom,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          if (structure.regionName != null)
            Text(
                '${structure.regionName}'
                '${structure.districtName != null ? ' / ${structure.districtName}' : ''}',
                style: const TextStyle(fontSize: 11, color: _kGray)),
          if (structure.contact != null && structure.contact!.isNotEmpty)
            Text('📞 ${structure.contact}',
                style: const TextStyle(fontSize: 11, color: _kGray)),
        ])),
        if (canEdit || canDelete)
          Column(children: [
            if (canEdit)
              GestureDetector(
                  onTap: onEdit,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: Colors.blue))),
            if (canDelete)
              GestureDetector(
                  onTap: onDelete,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: _kRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_outline,
                          size: 16, color: _kRed))),
          ]),
      ]),
    );
  }
}
