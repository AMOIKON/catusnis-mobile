// lib/features/structures/screens/structure_form_screen.dart

import 'package:flutter/material.dart';
import '../../../core/utils/notify.dart';
import '../../deployments/services/deployment_service.dart';
import '../models/structure_model.dart';
import '../services/structure_service.dart';

const _kPrimary = Color(0xFF0F4C81);
const _kBg = Color(0xFFF0F4F8);
const _kGray = Color(0xFF607D8B);

class StructureFormScreen extends StatefulWidget {
  final StructureModel? structure;
  const StructureFormScreen({super.key, this.structure});
  @override
  State<StructureFormScreen> createState() => _StructureFormScreenState();
}

class _StructureFormScreenState extends State<StructureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StructureService();
  final _refService = DeploymentService();

  final _nomCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _districts = [];
  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedDistrict;

  bool _loading = false;
  bool _loadingDistricts = false;
  bool _submitting = false;
  bool get _isEdit => widget.structure != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nomCtrl.text = widget.structure!.nom;
      _contactCtrl.text = widget.structure!.contact ?? '';
    }
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      _regions = await _refService.getRegions();
      if (_isEdit && widget.structure!.regionId != null) {
        _selectedRegion = _regions
            .where((r) => r['id'] == widget.structure!.regionId)
            .toList()
            .firstOrNull;
        if (_selectedRegion != null) {
          _districts =
              await _refService.getDistricts(widget.structure!.regionId!);
          _selectedDistrict = _districts
              .where((d) => d['id'] == widget.structure!.districtId)
              .toList()
              .firstOrNull;
        }
      }
    } catch (_) {
      // ignore, le formulaire reste utilisable même sans préchargement
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRegionChanged(Map<String, dynamic>? region) async {
    setState(() {
      _selectedRegion = region;
      _selectedDistrict = null;
      _districts = [];
    });
    if (region == null) return;
    setState(() => _loadingDistricts = true);
    try {
      final districts = await _refService.getDistricts(region['id'] as int);
      if (mounted) setState(() => _districts = districts);
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final body = <String, dynamic>{
      'nom': _nomCtrl.text.trim(),
      'contact':
          _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      if (_selectedRegion != null) 'regionId': _selectedRegion!['id'],
      if (_selectedDistrict != null) 'districtId': _selectedDistrict!['id'],
    };

    try {
      final StructureModel result;
      if (_isEdit) {
        result = await _service.update(widget.structure!.id, body);
      } else {
        result = await _service.create(body);
      }
      if (!mounted) return;
      Notify.success(
        context,
        _isEdit
            ? 'Structure modifiée avec succès'
            : 'Structure créée avec succès',
      );
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      Notify.apiError(
          context, e, "Erreur lors de l'enregistrement de la structure");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Modifier la structure' : 'Nouvelle structure',
            style: const TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom de la structure *',
                          prefixIcon: const Icon(Icons.account_balance_outlined,
                              size: 18, color: _kGray),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedRegion,
                        isExpanded: true,
                        hint: const Text('Région'),
                        items: _regions
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r['regionName'] as String? ?? '')))
                            .toList(),
                        onChanged: _onRegionChanged,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.map_outlined,
                              size: 18, color: _kGray),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_loadingDistricts)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(children: [
                            SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _kPrimary)),
                            SizedBox(width: 12),
                            Text('Chargement des districts…',
                                style: TextStyle(fontSize: 13, color: _kGray)),
                          ]),
                        )
                      else
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedDistrict,
                          isExpanded: true,
                          hint: const Text('District'),
                          items: _districts
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d['DistrictName'] as String? ??
                                        d['districtName'] as String? ??
                                        ''),
                                  ))
                              .toList(),
                          onChanged: _districts.isEmpty
                              ? null
                              : (v) => setState(() => _selectedDistrict = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_city_outlined,
                                size: 18, color: _kGray),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _contactCtrl,
                        decoration: InputDecoration(
                          labelText: 'Contact',
                          prefixIcon: const Icon(Icons.phone_outlined,
                              size: 18, color: _kGray),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitting ? null : _submit,
        backgroundColor: _kPrimary,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_outlined, color: Colors.white),
        label: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer',
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
