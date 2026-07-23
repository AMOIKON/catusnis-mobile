// lib/features/vehicules/screens/vehicule_form_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/notify.dart';
import '../models/vehicule_model.dart';
import '../services/vehicule_service.dart';

const _kGreen = Color(0xFF2E7D32);

class VehiculeFormScreen extends StatefulWidget {
  final VehiculeModel? vehicule;
  const VehiculeFormScreen({super.key, this.vehicule});

  @override
  State<VehiculeFormScreen> createState() => _VehiculeFormScreenState();
}

class _VehiculeFormScreenState extends State<VehiculeFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = VehiculeService();
  bool _saving = false;
  String? _error;

  late TextEditingController _immatCtrl;
  late TextEditingController _marqueCtrl;
  late TextEditingController _modeleCtrl;
  late TextEditingController _couleurCtrl;
  late TextEditingController _kmCtrl;
  late TextEditingController _obsCtrl;

  String _type = 'VOITURE';
  String _statut = 'DISPONIBLE';

  static const _types = ['VOITURE', 'MOTO', 'CAMION', 'MINIBUS', 'AUTRE'];
  static const _statuts = [
    'DISPONIBLE',
    'EN_MISSION',
    'EN_PANNE',
    'EN_MAINTENANCE',
    'RETIRE'
  ];

  bool get _isEdit => widget.vehicule != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicule;
    _immatCtrl = TextEditingController(text: v?.immatriculation ?? '');
    _marqueCtrl = TextEditingController(text: v?.marque ?? '');
    _modeleCtrl = TextEditingController(text: v?.modele ?? '');
    _couleurCtrl = TextEditingController(text: v?.couleur ?? '');
    _kmCtrl = TextEditingController(text: v?.kilometrage?.toString() ?? '');
    _obsCtrl = TextEditingController(text: v?.observations ?? '');
    _type = v?.type ?? 'VOITURE';
    _statut = v?.statut ?? 'DISPONIBLE';
  }

  @override
  void dispose() {
    for (final c in [
      _immatCtrl,
      _marqueCtrl,
      _modeleCtrl,
      _couleurCtrl,
      _kmCtrl,
      _obsCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = {
      'immatriculation': _immatCtrl.text.trim().toUpperCase(),
      'type': _type,
      'statut': _statut,
      'marque':
          _marqueCtrl.text.trim().isEmpty ? null : _marqueCtrl.text.trim(),
      'modele':
          _modeleCtrl.text.trim().isEmpty ? null : _modeleCtrl.text.trim(),
      'couleur':
          _couleurCtrl.text.trim().isEmpty ? null : _couleurCtrl.text.trim(),
      'kilometrage': _kmCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_kmCtrl.text.trim()),
      'observations':
          _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await _svc.updateVehicule(widget.vehicule!.id, body);
      } else {
        await _svc.createVehicule(body);
      }
      if (mounted) {
        Notify.success(
          context,
          _isEdit
              ? 'Véhicule modifié avec succès'
              : 'Véhicule enregistré avec succès',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = msg;
        _saving = false;
      });
      if (mounted) {
        Notify.apiError(
          context,
          e,
          "Erreur lors de l'enregistrement du véhicule",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Modifier l\'engin' : 'Nouvel engin',
            style: const TextStyle(fontSize: 17, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.danger, fontSize: 12))),
                ]),
              ),
            _Field(
              ctrl: _immatCtrl,
              label: 'Immatriculation *',
              icon: Icons.credit_card_outlined,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Immatriculation requise' : null,
            ),
            const SizedBox(height: 14),
            _DropdownField<String>(
              label: 'Type d\'engin',
              icon: Icons.directions_car_outlined,
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
            Row(children: [
              Expanded(
                  child: _Field(
                      ctrl: _marqueCtrl,
                      label: 'Marque',
                      icon: Icons.label_outline)),
              const SizedBox(width: 12),
              Expanded(
                  child: _Field(
                      ctrl: _modeleCtrl,
                      label: 'Modèle',
                      icon: Icons.model_training_outlined)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: _Field(
                      ctrl: _couleurCtrl,
                      label: 'Couleur',
                      icon: Icons.palette_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _Field(
                      ctrl: _kmCtrl,
                      label: 'Kilométrage',
                      icon: Icons.speed_outlined,
                      keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 14),
            _Field(
                ctrl: _obsCtrl,
                label: 'Observations',
                icon: Icons.notes_outlined,
                maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
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
                        _isEdit
                            ? 'Enregistrer les modifications'
                            : 'Ajouter l\'engin',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets réutilisables (partagés avec incident et maintenance forms) ────────

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
