// lib/features/fournitures/screens/fourniture_form_screen.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/fourniture_model.dart';
import '../services/fourniture_service.dart';

const _kBlue = Color(0xFF1565C0);

class FournitureFormScreen extends StatefulWidget {
  final FournitureModel? fourniture;
  const FournitureFormScreen({super.key, this.fourniture});

  @override
  State<FournitureFormScreen> createState() => _FournitureFormState();
}

class _FournitureFormState extends State<FournitureFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = FournitureService();
  bool _saving = false;
  String? _error;

  late TextEditingController _desCtrl;
  late TextEditingController _uniteCtrl;
  late TextEditingController _qteCtrl;
  late TextEditingController _fournCtrl;
  late TextEditingController _prixCtrl;
  String _categorie = 'AUTRE';

  static const _categories = [
    'INFORMATIQUE',
    'MOBILIER',
    'PAPETERIE',
    'BUREAUTIQUE',
    'ELECTROMENAGER',
    'AUTRE',
  ];
  static const _catLabels = {
    'INFORMATIQUE': 'Informatique',
    'MOBILIER': 'Mobilier',
    'PAPETERIE': 'Papeterie',
    'BUREAUTIQUE': 'Bureautique',
    'ELECTROMENAGER': 'Électroménager',
    'AUTRE': 'Autre',
  };

  bool get _isEdit => widget.fourniture != null;

  @override
  void initState() {
    super.initState();
    final f = widget.fourniture;
    _desCtrl = TextEditingController(text: f?.designation ?? '');
    _uniteCtrl = TextEditingController(text: f?.unite ?? '');
    _qteCtrl = TextEditingController(text: f?.quantite.toString() ?? '0');
    _fournCtrl = TextEditingController(text: f?.fournisseur ?? '');
    _prixCtrl = TextEditingController(text: f?.prixUnitaire?.toString() ?? '');
    _categorie = f?.categorie ?? 'AUTRE';
  }

  @override
  void dispose() {
    _desCtrl.dispose();
    _uniteCtrl.dispose();
    _qteCtrl.dispose();
    _fournCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = {
      'designation': _desCtrl.text.trim(),
      'categorie': _categorie,
      'quantite': int.tryParse(_qteCtrl.text.trim()) ?? 0,
      'unite': _uniteCtrl.text.trim().isEmpty ? null : _uniteCtrl.text.trim(),
      'fournisseur':
          _fournCtrl.text.trim().isEmpty ? null : _fournCtrl.text.trim(),
      'prixUnitaire': double.tryParse(_prixCtrl.text.trim()),
    };

    try {
      if (_isEdit)
        await _svc.updateFourniture(widget.fourniture!.id, body);
      else
        await _svc.createFourniture(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          title: Text(_isEdit ? 'Modifier l\'article' : 'Nouvel article'),
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
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.danger)),
                ),
              _Field(
                ctrl: _desCtrl,
                label: 'Désignation *',
                icon: Icons.label_outline,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Désignation requise' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _categorie,
                onChanged: (v) => setState(() => _categorie = v!),
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_catLabels[c] ?? c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _Field(
                  ctrl: _qteCtrl,
                  label: 'Quantité *',
                  icon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (int.tryParse(v ?? '') == null) ? 'Nombre requis' : null,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _Field(
                        ctrl: _uniteCtrl,
                        label: 'Unité',
                        icon: Icons.straighten_outlined)),
              ]),
              const SizedBox(height: 14),
              _Field(
                  ctrl: _fournCtrl,
                  label: 'Fournisseur',
                  icon: Icons.business_outlined),
              const SizedBox(height: 14),
              _Field(
                  ctrl: _prixCtrl,
                  label: 'Prix unitaire (FCFA)',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
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
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter l\'article',
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

// ── Widget réutilisable ───────────────────────────────────────────────────────
// ✅ maxLines supprimé — jamais utilisé dans ce formulaire (hardcodé à 1)
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        maxLines: 1,
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
