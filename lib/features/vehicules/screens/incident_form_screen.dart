// lib/features/vehicules/screens/incident_form_screen.dart

import 'package:flutter/material.dart';
import '../models/vehicule_model.dart';
import '../services/vehicule_service.dart';

class IncidentFormScreen extends StatefulWidget {
  final VehiculeIncidentModel? incident;
  const IncidentFormScreen({super.key, this.incident});

  @override
  State<IncidentFormScreen> createState() => _IncidentFormState();
}

class _IncidentFormState extends State<IncidentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = VehiculeService();
  bool _saving = false;

  late TextEditingController _descCtrl;
  late TextEditingController _lieuCtrl;
  late TextEditingController _coutCtrl;
  late TextEditingController _signaleParCtrl;

  String _type = 'PANNE';
  String _statut = 'EN_ATTENTE';
  final String _dateIncident = DateTime.now().toIso8601String().split('T')[0];

  static const _types = ['ACCIDENT', 'PANNE', 'VOL', 'AUTRE'];
  static const _statuts = ['EN_ATTENTE', 'EN_COURS', 'RESOLU'];

  bool get _isEdit => widget.incident != null;

  @override
  void initState() {
    super.initState();
    final inc = widget.incident;
    _descCtrl = TextEditingController(text: inc?.description ?? '');
    _lieuCtrl = TextEditingController(text: inc?.lieuIncident ?? '');
    _coutCtrl = TextEditingController(text: inc?.coutEstime?.toString() ?? '');
    _signaleParCtrl = TextEditingController(text: inc?.signalePar ?? '');
    _type = inc?.typeIncident ?? 'PANNE';
    _statut = inc?.statut ?? 'EN_ATTENTE';
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _lieuCtrl, _coutCtrl, _signaleParCtrl])
      c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'vehiculeId': widget.incident?.vehiculeId ?? 0,
      'typeIncident': _type,
      'statut': _statut,
      'dateIncident': _dateIncident,
      'description': _descCtrl.text.trim(),
      'lieuIncident': _lieuCtrl.text.trim(),
      'signalePar': _signaleParCtrl.text.trim(),
      'coutEstime': double.tryParse(_coutCtrl.text.trim()),
    };

    try {
      if (_isEdit)
        await _svc.updateIncident(widget.incident!.id, body);
      else
        await _svc.createIncident(body);
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
          backgroundColor: const Color(0xFFFF6F00),
          foregroundColor: Colors.white,
          title:
              Text(_isEdit ? 'Modifier l\'incident' : 'Signaler un incident'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(children: [
              _DropdownField<String>(
                label: 'Type d\'incident',
                icon: Icons.warning_amber_outlined,
                value: _type,
                items: _types,
                displayLabel: (v) => v,
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
                  ctrl: _lieuCtrl,
                  label: 'Lieu de l\'incident',
                  icon: Icons.location_on_outlined),
              const SizedBox(height: 14),
              _Field(
                  ctrl: _signaleParCtrl,
                  label: 'Signalé par',
                  icon: Icons.person_outline),
              const SizedBox(height: 14),
              _Field(
                  ctrl: _coutCtrl,
                  label: 'Coût estimé (FCFA)',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
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
                      : Text(_isEdit ? 'Enregistrer' : 'Signaler l\'incident',
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
