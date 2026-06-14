// lib/features/acquisitions/screens/acquisition_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/acquisition_model.dart';
import '../services/acquisition_form_service.dart';

class AcquisitionFormScreen extends StatefulWidget {
  final AcquisitionModel? model;
  const AcquisitionFormScreen({super.key, this.model});
  @override
  State<AcquisitionFormScreen> createState() => _AcquisitionFormScreenState();
}

class _AcquisitionFormScreenState extends State<AcquisitionFormScreen> {
  final AcquisitionFormService _service = AcquisitionFormService();
  final _formKey = GlobalKey<FormState>();
  final _tagCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');

  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _partners = [];
  Map<String, dynamic>? _selectedType;
  Map<String, dynamic>? _selectedPartner;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  bool _submitting = false;

  bool get _isEdit => widget.model != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _tagCtrl.text = widget.model!.tag;
      _serialCtrl.text = widget.model!.serial;
      _quantityCtrl.text = '${widget.model!.quantity ?? 1}';
      if (widget.model!.dateAcq != null) {
        try {
          _selectedDate =
              DateTime.parse(widget.model!.dateAcq!.substring(0, 10));
        } catch (_) {}
      }
    } else {
      _tagCtrl.text =
          'TAG-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    _initData();
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    _serialCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    try {
      final results =
          await Future.wait([_service.getTypes(), _service.getPartners()]);
      setState(() {
        _types = results[0];
        _partners = results[1];
        _loading = false;
      });
      if (_isEdit) {
        setState(() {
          _selectedType = _types
              .where((t) => t['typeName'] == widget.model!.typeName)
              .firstOrNull;
          _selectedPartner = _partners
              .where((p) => p['partnerName'] == widget.model!.partnerName)
              .firstOrNull;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showError('Veuillez sélectionner un type.');
      return;
    }

    final connectivity = context.read<ConnectivityService>();
    final sync = context.read<SyncService>();
    setState(() => _submitting = true);

    final body = <String, dynamic>{
      'image': '',
      'tag': _tagCtrl.text.trim(),
      'serial': _serialCtrl.text.trim(),
      'quantity': int.tryParse(_quantityCtrl.text) ?? 1,
      'typesId': _selectedType!['id'] as int,
      'dateAcq': _selectedDate.millisecondsSinceEpoch,
    };
    if (_selectedPartner != null)
      body['partnerId'] = _selectedPartner!['id'] as int;

    try {
      if (_isEdit) {
        await _service.updateAcquisition(widget.model!.id, body);
        if (!mounted) return;
        _showSuccessDialog(Icons.edit_note, AppTheme.primary,
            'Acquisition mise à jour !', _tagCtrl.text);
      } else if (connectivity.isOffline) {
        await sync.saveOffline(module: 'acquisitions', data: body);
        if (!mounted) return;
        _showSuccessDialog(Icons.cloud_upload_outlined, Colors.orange,
            'Sauvegardé hors ligne !', 'Sera synchronisé à la reconnexion');
      } else {
        await _service.createAcquisition(body);
        if (!mounted) return;
        _showSuccessDialog(Icons.check_circle_outline, AppTheme.success,
            'Acquisition créée !', _tagCtrl.text);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog(
          IconData icon, Color color, String title, String subtitle) =>
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 40)),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(subtitle,
                      style: const TextStyle(color: AppTheme.gray),
                      textAlign: TextAlign.center),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child:
                        const Text('OK', style: TextStyle(color: Colors.white)),
                  )
                ],
              ));

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityService>().isOffline;
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier acquisition' : 'Nouvelle acquisition'),
        actions: [
          if (isOffline && !_isEdit)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('Hors ligne',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                ])),
          if (_submitting)
            const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)))
          else
            TextButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer',
                    style: const TextStyle(color: Colors.white))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOffline && !_isEdit)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3))),
                          child: const Row(children: [
                            Icon(Icons.wifi_off,
                                color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Mode hors ligne — La donnée sera synchronisée à la reconnexion',
                                    style: TextStyle(
                                        color: Colors.orange, fontSize: 12))),
                          ]),
                        ),
                      _sectionTitle('Identification', Icons.qr_code_outlined),
                      _card([
                        _buildTextField(
                            controller: _tagCtrl,
                            label: 'Tag (code unique) *',
                            icon: Icons.label_outline,
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null),
                        const SizedBox(height: 12),
                        _buildTextField(
                            controller: _serialCtrl,
                            label: 'Numéro de série *',
                            icon: Icons.numbers_outlined,
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null),
                        const SizedBox(height: 12),
                        _buildTextField(
                            controller: _quantityCtrl,
                            label: 'Quantité *',
                            icon: Icons.inventory_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Champ requis' : null),
                      ]),
                      _sectionTitle(
                          'Type d\'équipement', Icons.devices_outlined),
                      _card([
                        // ── Type avec recherche ───────────────────────────
                        _SearchableDropdown<Map<String, dynamic>>(
                          label: 'Type d\'équipement *',
                          icon: Icons.devices_outlined,
                          value: _selectedType,
                          items: _types,
                          display: (t) =>
                              '${t['typeName']} — ${t['marque'] ?? ''} ${t['modele'] ?? ''}'
                                  .trim(),
                          hint: 'Rechercher un type d\'équipement...',
                          onChanged: (v) => setState(() => _selectedType = v),
                          enabled: true,
                        ),
                      ]),
                      _sectionTitle(
                          'Partenaire & Date', Icons.business_outlined),
                      _card([
                        // ── Partenaire avec recherche ─────────────────────
                        _SearchableDropdown<Map<String, dynamic>>(
                          label: 'Partenaire',
                          icon: Icons.business_outlined,
                          value: _selectedPartner,
                          items: _partners,
                          display: (p) => p['partnerName'] as String? ?? '',
                          hint: 'Rechercher un partenaire...',
                          onChanged: (v) =>
                              setState(() => _selectedPartner = v),
                          enabled: true,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppTheme.gray),
                              const SizedBox(width: 10),
                              Text(
                                  '${_selectedDate.day.toString().padLeft(2, '0')}/'
                                  '${_selectedDate.month.toString().padLeft(2, '0')}/'
                                  '${_selectedDate.year}',
                                  style: const TextStyle(color: AppTheme.dark)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 80),
                    ]),
              )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _submit,
        icon: Icon(
            isOffline && !_isEdit
                ? Icons.cloud_upload_outlined
                : Icons.save_outlined,
            color: Colors.white),
        label: Text(
            _isEdit
                ? 'Mettre à jour'
                : (isOffline ? 'Sauvegarder hors ligne' : 'Enregistrer'),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: _isEdit
            ? AppTheme.primary
            : (isOffline ? Colors.orange : AppTheme.primary),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.dark)),
      ]));

  Widget _card(List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _buildTextField(
          {required TextEditingController controller,
          required String label,
          required IconData icon,
          String? Function(String?)? validator,
          TextInputType keyboardType = TextInputType.text}) =>
      TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, size: 18, color: AppTheme.gray),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: AppTheme.primary, width: 1.5))));
}

// ═════════════════════════════════════════════════════════════════════════════
// Widget dropdown avec recherche intégrée (partagé)
// ═════════════════════════════════════════════════════════════════════════════
class _SearchableDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) display;
  final String hint;
  final void Function(T?)? onChanged;
  final bool enabled;
  final String? emptyText;

  const _SearchableDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.display,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: enabled && onChanged != null ? () => _openSheet(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppTheme.primary.withOpacity(0.5)
                : Colors.transparent,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              size: 18, color: hasValue ? AppTheme.primary : AppTheme.gray),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
            hasValue ? display(value as T) : label,
            style: TextStyle(
                fontSize: 13,
                color: hasValue ? AppTheme.dark : AppTheme.gray,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          )),
          if (hasValue && enabled && onChanged != null)
            GestureDetector(
                onTap: () => onChanged!(null),
                child: const Icon(Icons.close, size: 16, color: AppTheme.gray))
          else
            Icon(enabled ? Icons.keyboard_arrow_down : Icons.lock_outline,
                size: 18, color: enabled ? AppTheme.gray : Colors.grey[400]),
        ]),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchSheet<T>(
        label: label,
        icon: icon,
        items: items,
        display: display,
        hint: hint,
        currentValue: value,
        emptyText: emptyText ?? 'Aucun résultat',
        onSelected: (selected) {
          Navigator.pop(ctx);
          onChanged?.call(selected);
        },
      ),
    );
  }
}

class _SearchSheet<T> extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<T> items;
  final String Function(T) display;
  final String hint;
  final T? currentValue;
  final String emptyText;
  final void Function(T) onSelected;

  const _SearchSheet(
      {required this.label,
      required this.icon,
      required this.items,
      required this.display,
      required this.hint,
      required this.currentValue,
      required this.emptyText,
      required this.onSelected});

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  final _searchCtrl = TextEditingController();
  List<T> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.items);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final kw = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = kw.isEmpty
          ? List.from(widget.items)
          : widget.items
              .where((item) => widget.display(item).toLowerCase().contains(kw))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Icon(widget.icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark)),
              const Spacer(),
              Text('${_filtered.length} / ${widget.items.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.gray, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _searchCtrl.clear())
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppTheme.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(widget.emptyText,
                            style: const TextStyle(
                                color: AppTheme.gray, fontSize: 14)),
                      ]))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final isSelected = widget.currentValue != null &&
                          widget.display(widget.currentValue as T) ==
                              widget.display(item);
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(widget.icon,
                              size: 18,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.gray),
                          title: Text(widget.display(item),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.dark,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.primary, size: 20)
                              : null,
                          tileColor: isSelected
                              ? AppTheme.primary.withOpacity(0.05)
                              : null,
                          onTap: () => widget.onSelected(item),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
