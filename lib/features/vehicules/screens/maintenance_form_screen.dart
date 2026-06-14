// lib/features/vehicules/screens/maintenance_form_screen.dart

import 'package:flutter/material.dart';
import '../models/vehicule_model.dart';
import '../services/vehicule_service.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final VehiculeMaintenanceModel? maintenance;
  const MaintenanceFormScreen({super.key, this.maintenance});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = VehiculeService();
  bool _saving = false;

  late TextEditingController _descCtrl;
  late TextEditingController _prestCtrl;
  late TextEditingController _coutCtrl;
  late TextEditingController _kmCtrl;

  String _type = 'PREVENTIVE';
  String _statut = 'PLANIFIEE';

  static const _types = ['PREVENTIVE', 'CURATIVE'];
  static const _statuts = ['PLANIFIEE', 'EN_COURS', 'TERMINEE'];

  bool get _isEdit => widget.maintenance != null;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _prestCtrl = TextEditingController(text: m?.prestataire ?? '');
    _coutCtrl = TextEditingController(text: m?.coutReel?.toString() ?? '');
    _kmCtrl = TextEditingController(
        text: m?.kilometrageIntervention?.toString() ?? '');
    _type = m?.typeMaintenance ?? 'PREVENTIVE';
    _statut = m?.statut ?? 'PLANIFIEE';
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _prestCtrl, _coutCtrl, _kmCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'vehiculeId': widget.maintenance?.vehiculeId ?? 0,
      'typeMaintenance': _type,
      'statut': _statut,
      'dateMaintenance': DateTime.now().toIso8601String().split('T')[0],
      'description': _descCtrl.text.trim(),
      'prestataire': _prestCtrl.text.trim(),
      'coutReel': double.tryParse(_coutCtrl.text.trim()),
      'kilometrageIntervention': int.tryParse(_kmCtrl.text.trim()),
    };

    try {
      if (_isEdit)
        await _svc.updateMaintenance(widget.maintenance!.id, body);
      else
        await _svc.createMaintenance(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFC62828),
          foregroundColor: Colors.white,
          title: Text(_isEdit
              ? 'Modifier la maintenance'
              : 'Planifier une maintenance'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(children: [
              _DropdownField<String>(
                label: 'Type',
                icon: Icons.build_outlined,
                value: _type,
                items: _types,
                displayLabel: (v) =>
                    v == 'PREVENTIVE' ? 'Préventive' : 'Curative',
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 14),
              _DropdownField<String>(
                label: 'Statut',
                icon: Icons.info_outline,
                value: _statut,
                items: _statuts,
                displayLabel: (v) => v.replaceAll('_', ' '),
                onChanged: (v) => setState(() => _statut = v!),
              ),
              const SizedBox(height: 14),
              _Field(
                ctrl: _descCtrl,
                label: 'Description *',
                icon: Icons.notes_outlined,
                maxLines: 3,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Description requise' : null,
              ),
              const SizedBox(height: 14),
              _Field(
                  ctrl: _prestCtrl,
                  label: 'Prestataire',
                  icon: Icons.business_outlined),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _Field(
                  ctrl: _coutCtrl,
                  label: 'Coût réel (FCFA)',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _Field(
                  ctrl: _kmCtrl,
                  label: 'Kilométrage',
                  icon: Icons.speed_outlined,
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
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
                      : Text(
                          _isEdit ? 'Enregistrer' : 'Planifier la maintenance',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      );
}

// ── Widgets réutilisables ─────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
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

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) displayLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.displayLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        ),
        items: items
            .map(
                (v) => DropdownMenuItem(value: v, child: Text(displayLabel(v))))
            .toList(),
      );
}
