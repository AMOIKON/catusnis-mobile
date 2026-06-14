// lib/features/archives/screens/archive_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/network_error_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/archive_model.dart';
import '../services/archive_service.dart';
import 'archive_form_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});
  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final ArchiveService _service = ArchiveService();
  final _scrollController = ScrollController();

  List<ArchiveModel> _allItems = [];
  bool _loading = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _page = 0;
  String? _selectedType;

  // ✅ CORRIGÉ : ?.role. au lieu de ?.role?.
  bool _canEdit(BuildContext ctx) {
    final role = ctx.read<AuthProvider>().user?.role.toUpperCase() ?? '';
    return role.contains('ADMIN') || role.contains('TECHNICIEN');
  }

  // ✅ CORRIGÉ : ?.role. au lieu de ?.role?.
  bool _canDelete(BuildContext ctx) {
    final role = ctx.read<AuthProvider>().user?.role.toUpperCase() ?? '';
    return role.contains('SUPER') && role.contains('ADMIN');
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadAll({bool reset = false}) async {
    if (_loading) return;
    if (reset)
      setState(() {
        _page = 0;
        _hasMore = true;
        _allItems = [];
        _hasError = false;
      });
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final result = await _service.getArchives(
          page: _page, size: 50, type: _selectedType);
      if (!mounted) return;
      final newItems = List<ArchiveModel>.from(result['items'] as List);
      setState(() {
        _allItems.addAll(newItems);
        _hasMore = (_page + 1) < (result['totalPages'] as int);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    _page++;
    await _loadAll();
  }

  Map<String, List<ArchiveModel>> get _groupedByCategorie {
    final map = <String, List<ArchiveModel>>{};
    for (final arch in _allItems) {
      map.putIfAbsent(arch.categorie, () => []).add(arch);
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length)));
  }

  int _countType(String type) => _allItems.where((a) => a.type == type).length;

  String _catLabel(String cat) {
    switch (cat) {
      case 'INTERVENTION':
        return 'Intervention';
      case 'DEPLOIEMENT':
        return 'Déploiement';
      case 'ACQUISITION':
        return 'Acquisition';
      case 'BOOKLET':
        return 'Cahier';
      case 'ACTIVE':
        return 'Actif';
      default:
        return 'Autre';
    }
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'INTERVENTION':
        return AppTheme.warning;
      case 'DEPLOIEMENT':
        return AppTheme.success;
      case 'ACQUISITION':
        return AppTheme.primary;
      case 'BOOKLET':
        return Colors.purple;
      case 'ACTIVE':
        return Colors.teal;
      default:
        return AppTheme.gray;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'INTERVENTION':
        return Icons.build_outlined;
      case 'DEPLOIEMENT':
        return Icons.local_shipping_outlined;
      case 'ACQUISITION':
        return Icons.inventory_2_outlined;
      case 'BOOKLET':
        return Icons.menu_book_outlined;
      case 'ACTIVE':
        return Icons.flash_on_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Future<void> _deleteArchive(BuildContext ctx, ArchiveModel arch) async {
    final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Confirmer la suppression'),
              content: Text(
                  'Supprimer "${arch.titre}" ?\nCette action est irréversible.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
    if (confirm != true) return;
    try {
      await _service.deleteArchive(arch.id);
      if (!mounted) return;
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Archive supprimée'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating));
      _loadAll(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _allItems.isEmpty)
      return NetworkErrorWidget(onRetry: () => _loadAll(reset: true));
    final grouped = _groupedByCategorie;
    final isFiltered = _selectedType != null;

    return Stack(children: [
      Column(children: [
        // ── Barre résumé ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.gray, borderRadius: BorderRadius.circular(14)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _SummaryBadge(
                label: 'Total', count: _allItems.length, color: Colors.white),
            _SummaryBadge(
                label: 'Scannés',
                count: _countType('SCANNE'),
                color: isFiltered ? Colors.white : Colors.lightBlue.shade100),
            _SummaryBadge(
                label: 'Imprimés',
                count: _countType('IMPRIME'),
                color: isFiltered ? Colors.white : Colors.amber.shade100),
            _SummaryBadge(
                label: 'Catégories',
                count: grouped.length,
                color: isFiltered ? Colors.white : Colors.white70),
          ]),
        ),

        // ── Chips filtre type archive ─────────────────────────
        SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildChip(
                    null, 'Tous', Icons.all_inclusive_outlined, AppTheme.gray),
                const SizedBox(width: 8),
                _buildChip('SCANNE', 'Scanné', Icons.document_scanner_outlined,
                    AppTheme.primary),
                const SizedBox(width: 8),
                _buildChip('IMPRIME', 'Imprimé', Icons.print_outlined,
                    AppTheme.warning),
              ],
            )),

        if (isFiltered)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              Text(
                  '${_allItems.length} archive(s) · ${grouped.length} catégorie(s)',
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedType = null);
                  _loadAll(reset: true);
                },
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

        Expanded(
          child: _loading && _allItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : grouped.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _loadAll(reset: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: grouped.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == grouped.length) {
                            return const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()));
                          }
                          final entry = grouped.entries.elementAt(index);
                          return _CategorieCard(
                            categorie: entry.key,
                            items: entry.value,
                            catLabel: _catLabel,
                            catColor: _catColor,
                            catIcon: _catIcon,
                            onTap: () => _showCategorieDetail(
                                context, entry.key, entry.value),
                          );
                        },
                      ),
                    ),
        ),
      ]),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ArchiveFormScreen()));
            _loadAll(reset: true);
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.gray,
        ),
      ),
    ]);
  }

  Widget _buildChip(String? value, String label, IconData icon, Color color) {
    final sel = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = value);
        _loadAll(reset: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  void _showCategorieDetail(
      BuildContext context, String categorie, List<ArchiveModel> items) {
    final canEdit = _canEdit(context);
    final canDelete = _canDelete(context);
    final color = _catColor(categorie);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(_catIcon(categorie), color: color, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(_catLabel(categorie),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${items.length}',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold))),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final arch = items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: arch.isScanne
                                      ? AppTheme.primary.withOpacity(0.1)
                                      : AppTheme.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(arch.isScanne ? 'Scanné' : 'Imprimé',
                                  style: TextStyle(
                                      color: arch.isScanne
                                          ? AppTheme.primary
                                          : AppTheme.warning,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(arch.titre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.dark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                        if (arch.archivedBy != null) ...[
                          const SizedBox(height: 4),
                          Text('👤 ${arch.archivedBy}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.gray)),
                        ],
                        if (arch.archivedAt != null)
                          Text('📅 ${arch.archivedAt!.substring(0, 10)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.gray)),
                        if (arch.fileSizeLabel.isNotEmpty)
                          Text('📦 ${arch.fileSizeLabel}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.gray)),
                        if (canEdit || canDelete) ...[
                          const SizedBox(height: 8),
                          // ✅ CORRIGÉ : chaque bouton enveloppé dans Expanded
                          // pour éviter "BoxConstraints forces an infinite width".
                          Row(children: [
                            if (canEdit)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ArchiveFormScreen(
                                                archive: arch)));
                                    _loadAll(reset: true);
                                  },
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 14),
                                  label: const Text('Modifier',
                                      style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              ),
                            if (canEdit && canDelete) const SizedBox(width: 8),
                            if (canDelete)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _deleteArchive(ctx, arch),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 14, color: Colors.white),
                                  label: const Text('Supprimer',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              ),
                          ]),
                        ],
                      ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppTheme.gray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.archive_outlined,
                color: AppTheme.gray, size: 44)),
        const SizedBox(height: 16),
        Text(
            _selectedType != null
                ? 'Aucune archive de ce type'
                : 'Aucune archive',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark)),
        const SizedBox(height: 8),
        Text(
            _selectedType != null
                ? 'Essayez un autre filtre'
                : 'Les archives apparaîtront ici',
            style: const TextStyle(color: AppTheme.gray)),
      ]));
}

// ─────────────────────────────────────────────────────────────────────────────
class _CategorieCard extends StatelessWidget {
  final String categorie;
  final List<ArchiveModel> items;
  final String Function(String) catLabel;
  final Color Function(String) catColor;
  final IconData Function(String) catIcon;
  final VoidCallback onTap;

  const _CategorieCard({
    required this.categorie,
    required this.items,
    required this.catLabel,
    required this.catColor,
    required this.catIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = catColor(categorie);
    final total = items.length;
    final scannes = items.where((a) => a.isScanne).length;
    final imprimes = total - scannes;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ]),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(catIcon(categorie), color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(catLabel(categorie),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.dark)),
                    Text('$total archive${total > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.gray)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text('$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(
                  child: _StatChip(
                      label: 'Scannés',
                      count: scannes,
                      color: AppTheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Imprimés',
                      count: imprimes,
                      color: AppTheme.warning)),
            ]),
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(children: [
                  if (scannes > 0)
                    Expanded(
                        flex: scannes,
                        child: Container(height: 5, color: AppTheme.primary)),
                  if (imprimes > 0)
                    Expanded(
                        flex: imprimes,
                        child: Container(height: 5, color: AppTheme.warning)),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('Voir les détails',
                  style:
                      TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 11, color: color.withOpacity(0.8)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(
      {required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryBadge(
      {required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: TextStyle(color: color.withOpacity(0.85), fontSize: 9)),
      ]);
}
