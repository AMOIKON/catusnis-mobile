// lib/features/deployments/screens/deployment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/location_service.dart';
import '../models/deployment_model.dart';
import '../providers/deployment_provider.dart';
import '../services/deployment_service.dart';

const _kGreen = Color(0xFF2E7D52);
const _kGreenLight = Color(0xFFE8F5EE);
const _kGreenBg = Color(0xFFF4FAF6);
const _kTextDark = Color(0xFF1A237E);
const _kTextGray = Color(0xFF546E7A);

class DeploymentFormScreen extends StatefulWidget {
  final DeploymentModel? deploymentExistant;
  const DeploymentFormScreen({super.key, this.deploymentExistant});
  @override
  State<DeploymentFormScreen> createState() => _DeploymentFormScreenState();
}

class _DeploymentFormScreenState extends State<DeploymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _observCtrl = TextEditingController();
  final _locationService = LocationService();

  DateTime? _dateRecep;
  bool _initialise = false;

  // ── Géolocalisation ────────────────────────────────────────────────────────
  LocationResult? _location;
  bool _locLoading = false;

  bool get _isEdit => widget.deploymentExistant != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final prov = context.read<DeploymentFormProvider>();
    await prov.initialiser(deploymentExistant: widget.deploymentExistant);
    if (!mounted) return;

    if (_isEdit) {
      final dep = widget.deploymentExistant!;
      _codeCtrl.text = dep.codeDep;
      _observCtrl.text = dep.observations ?? '';
      final dateRec = dep.dateReception;
      if (dateRec != null) {
        try {
          _dateRecep = DateTime.parse(dateRec);
        } catch (_) {
          _dateRecep = DateTime.now();
        }
      }
      _dateRecep ??= DateTime.now();
    } else {
      final code = await _generateCodeSafe();
      _codeCtrl.text = code;
      _dateRecep = DateTime.now();
      // Capturer GPS automatiquement à la création
      _captureLocation();
    }

    if (mounted) setState(() => _initialise = true);
  }

  Future<void> _captureLocation() async {
    setState(() => _locLoading = true);
    final result = await _locationService.getCurrentLocation();
    if (mounted)
      setState(() {
        _location = result;
        _locLoading = false;
      });
  }

  Future<String> _generateCodeSafe() async {
    try {
      return await DeploymentService().generateCode();
    } catch (_) {
      final rand = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000)
          .toString()
          .padLeft(4, '0');
      return 'DEP-${DateTime.now().year}-$rand';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _observCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kGreenBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Modifier déploiement' : 'Nouveau déploiement',
            style: const TextStyle(fontSize: 17, color: Colors.white)),
      ),
      body: Consumer<DeploymentFormProvider>(
        builder: (ctx, prov, _) {
          if (prov.loadingRef || !_initialise) {
            return const Center(
                child: CircularProgressIndicator(color: _kGreen));
          }
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (prov.errorMessage != null)
                      _BanniereErreur(message: prov.errorMessage!),

                    // ── Section GPS ──────────────────────────────────────────────
                    _SectionTitre(
                        titre: 'Localisation GPS',
                        icone: Icons.gps_fixed_outlined),
                    _Carte(children: [_buildLocationWidget()]),

                    // ── Informations générales ───────────────────────────────────
                    _SectionTitre(
                        titre: 'Informations générales',
                        icone: Icons.info_outline),
                    _Carte(children: [
                      _ChampTexte(
                        controller: _codeCtrl,
                        label: 'Code déploiement *',
                        icone: Icons.qr_code_outlined,
                        validator: (v) => v!.isEmpty ? 'Code requis' : null,
                      ),
                      const SizedBox(height: 12),
                      _PickerDate(
                        date: _dateRecep,
                        onPick: (d) => setState(() => _dateRecep = d),
                      ),
                      const SizedBox(height: 12),
                      _ChampTexte(
                        controller: _observCtrl,
                        label: 'Observations',
                        icone: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                    ]),

                    // ── Localisation ─────────────────────────────────────────────
                    _SectionTitre(
                        titre: 'Localisation',
                        icone: Icons.location_on_outlined),
                    _Carte(children: [
                      _DropdownRecherche<Map<String, dynamic>>(
                        label: 'Région *',
                        icone: Icons.map_outlined,
                        valeur: prov.selectedRegion,
                        items: prov.regions,
                        afficher: (r) => r['regionName'] as String? ?? '',
                        hint: 'Rechercher une région…',
                        onChanged: prov.selectionnerRegion,
                        enabled: true,
                        emptyText: 'Aucune région disponible',
                      ),
                      const SizedBox(height: 12),
                      prov.loadingDistricts
                          ? _LigneChargement('Chargement des districts…')
                          : _DropdownRecherche<Map<String, dynamic>>(
                              label: 'District *',
                              icone: Icons.location_city_outlined,
                              valeur: prov.selectedDistrict,
                              items: prov.districts,
                              afficher: (d) =>
                                  d['DistrictName'] as String? ??
                                  d['districtName'] as String? ??
                                  '',
                              hint: 'Rechercher un district…',
                              onChanged: prov.districts.isEmpty
                                  ? null
                                  : prov.selectionnerDistrict,
                              enabled: prov.districts.isNotEmpty,
                              emptyText: prov.selectedRegion == null
                                  ? "Sélectionnez d'abord une région"
                                  : 'Aucun district disponible',
                            ),
                      const SizedBox(height: 12),
                      prov.loadingHealths
                          ? _LigneChargement('Chargement des sites…')
                          : _DropdownRecherche<Map<String, dynamic>>(
                              label: 'Site de santé *',
                              icone: Icons.local_hospital_outlined,
                              valeur: prov.selectedHealth,
                              items: prov.healths,
                              afficher: (h) => h['healthName'] as String? ?? '',
                              hint: 'Rechercher un site…',
                              onChanged: prov.healths.isEmpty
                                  ? null
                                  : prov.selectionnerHealth,
                              enabled: prov.healths.isNotEmpty,
                              emptyText: prov.selectedDistrict == null
                                  ? "Sélectionnez d'abord un district"
                                  : 'Aucun site disponible',
                            ),
                    ]),

                    // ── Application & Partenaires ────────────────────────────────
                    _SectionTitre(
                        titre: 'Application & Partenaires',
                        icone: Icons.apps_outlined),
                    _Carte(children: [
                      _DropdownSimple<Map<String, dynamic>>(
                        label: 'Application',
                        icone: Icons.apps_outlined,
                        valeur: prov.selectedApp,
                        items: prov.apps,
                        afficher: (a) =>
                            '${a['nom'] ?? a['appsName'] ?? ''}${a['version'] != null ? ' ${a['version']}' : ''}',
                        onChanged: prov.selectionnerApp,
                      ),
                      const SizedBox(height: 12),
                      _DropdownSimple<Map<String, dynamic>>(
                        label: 'Partenaire principal',
                        icone: Icons.business_outlined,
                        valeur: prov.selectedPartnerPrincipal,
                        items: prov.partners,
                        afficher: (p) =>
                            p['nom'] as String? ??
                            p['partnerName'] as String? ??
                            '',
                        onChanged: prov.selectionnerPartnerPrincipal,
                      ),
                      const SizedBox(height: 12),
                      _DropdownSimple<Map<String, dynamic>>(
                        label: 'Partenaire secondaire',
                        icone: Icons.business_center_outlined,
                        valeur: prov.selectedPartnerSecondaire,
                        items: prov.partners,
                        afficher: (p) =>
                            p['nom'] as String? ??
                            p['partnerName'] as String? ??
                            '',
                        onChanged: prov.selectionnerPartnerSecondaire,
                      ),
                    ]),

                    // ── Équipements ──────────────────────────────────────────────
                    _SectionTitre(
                      titre: 'Équipements (${prov.equipementLignes.length})',
                      icone: Icons.medical_services_outlined,
                      action: TextButton.icon(
                        onPressed: prov.ajouterLigne,
                        icon: const Icon(Icons.add, size: 16, color: _kGreen),
                        label: const Text('Ajouter',
                            style: TextStyle(
                                color: _kGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    ...prov.equipementLignes.asMap().entries.map(
                          (entry) => _LigneEquipement(
                            index: entry.key,
                            ligne: entry.value,
                            total: prov.equipementLignes.length,
                            onDelete: () => prov.supprimerLigne(entry.key),
                            onTypeChange: (tn, d) =>
                                prov.mettreAJourTypeLigne(entry.key, tn, d),
                          ),
                        ),
                    const SizedBox(height: 8),
                  ]),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<DeploymentFormProvider>(
        builder: (_, prov, __) => FloatingActionButton.extended(
          onPressed: prov.submitting ? null : () => _soumettre(prov),
          backgroundColor: _kGreen,
          icon: prov.submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, color: Colors.white),
          label: Text(_isEdit ? 'Mettre à jour' : 'Enregistrer',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ── Widget GPS ──────────────────────────────────────────────────────────────
  Widget _buildLocationWidget() {
    if (_locLoading) {
      return const Row(children: [
        SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen)),
        SizedBox(width: 12),
        Text('Localisation en cours…',
            style: TextStyle(fontSize: 13, color: _kTextGray)),
      ]);
    }
    if (_location != null) {
      return Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.gps_fixed, color: _kGreen, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Position capturée ✓',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: _kGreen)),
          Text(_location!.label,
              style: const TextStyle(fontSize: 11, color: _kTextGray)),
          if (_location!.accuracy != null)
            Text('Précision : ±${_location!.accuracy!.toStringAsFixed(0)} m',
                style: const TextStyle(fontSize: 10, color: _kTextGray)),
        ])),
        GestureDetector(
          onTap: _captureLocation,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh, size: 14, color: _kGreen),
                SizedBox(width: 4),
                Text('Actualiser',
                    style: TextStyle(fontSize: 11, color: _kGreen)),
              ])),
        ),
      ]);
    }
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.gps_off, color: Colors.orange, size: 20)),
      const SizedBox(width: 12),
      const Expanded(
          child: Text('Position non disponible',
              style: TextStyle(fontSize: 13, color: _kTextGray))),
      GestureDetector(
        onTap: _captureLocation,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.my_location, size: 14, color: _kGreen),
              SizedBox(width: 4),
              Text('Localiser', style: TextStyle(fontSize: 11, color: _kGreen)),
            ])),
      ),
    ]);
  }

  Future<void> _soumettre(DeploymentFormProvider prov) async {
    if (!_formKey.currentState!.validate()) return;
    final result = await prov.soumettre(
      _codeCtrl.text.trim(),
      _dateRecep != null
          ? '${_dateRecep!.year}-${_dateRecep!.month.toString().padLeft(2, '0')}-${_dateRecep!.day.toString().padLeft(2, '0')}'
          : null,
      _observCtrl.text.trim().isEmpty ? null : _observCtrl.text.trim(),
      latitude: _location?.latitude,
      longitude: _location?.longitude,
    );
    if (!mounted) return;
    if (result != null) _showSuccess(result);
  }

  void _showSuccess(DeploymentModel result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: _kGreenLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: _kGreen, size: 40)),
          const SizedBox(height: 16),
          Text(_isEdit ? 'Déploiement mis à jour !' : 'Déploiement créé !',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark)),
          const SizedBox(height: 6),
          Text(result.codeDep,
              style: const TextStyle(color: _kTextGray, fontSize: 13)),
          if (_location != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on, size: 13, color: _kGreen),
                const SizedBox(width: 4),
                Text(_location!.label,
                    style: const TextStyle(fontSize: 10, color: _kGreen)),
              ]),
            ),
          ],
        ]),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, result);
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIGNE ÉQUIPEMENT (identique à l'original)
// ─────────────────────────────────────────────────────────────────────────────
class _LigneEquipement extends StatefulWidget {
  final int index;
  final EquipementLigne ligne;
  final int total;
  final VoidCallback onDelete;
  final void Function(String?, String?) onTypeChange;

  const _LigneEquipement({
    required this.index,
    required this.ligne,
    required this.total,
    required this.onDelete,
    required this.onTypeChange,
  });
  @override
  State<_LigneEquipement> createState() => _LigneEquipementState();
}

class _LigneEquipementState extends State<_LigneEquipement> {
  static const List<String> _types = [
    'Échographe',
    'Tensiomètre',
    'Glucomètre',
    'Oxymètre',
    'Stéthoscope',
    'Thermomètre',
    'Défibrillateur',
    'Électrocardiographe',
    'Microscope',
    'Centrifugeuse',
    'Réfrigérateur médical',
    "Table d'examen",
    'Lit médicalisé',
    'Chaise roulante',
    'Brancard',
    'Onduleur',
    'Groupe électrogène',
    'Climatiseur médical',
    'Autre',
  ];

  bool _expanded = true;

  String? get _dropdownValue {
    final v = widget.ligne.typeName;
    return (v != null && _types.contains(v)) ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final num = widget.index + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: _expanded
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                      color: _kGreen, shape: BoxShape.circle),
                  child: Center(
                      child: Text('$num',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)))),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      widget.ligne.typeName?.isNotEmpty == true
                          ? widget.ligne.typeName!
                          : 'Équipement $num',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _kTextDark))),
              if (widget.ligne.numeroSerieCtrl.text.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(widget.ligne.numeroSerieCtrl.text,
                        style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: _kTextGray))),
              if (widget.total > 1)
                GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.red))),
              const SizedBox(width: 6),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _kTextGray,
                  size: 20),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(children: [
              DropdownButtonFormField<String>(
                value: _dropdownValue,
                isExpanded: true,
                hint: const Text("Type d'équipement *",
                    style: TextStyle(color: _kTextGray, fontSize: 13)),
                items: _types
                    .map((s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  setState(() => widget.ligne.typeName = val);
                  widget.onTypeChange(val, val);
                },
                validator: (v) => v == null || v.isEmpty ? 'Type requis' : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined,
                      size: 16, color: _kTextGray),
                  filled: true,
                  fillColor: _kGreenBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kGreen, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.ligne.numeroSerieCtrl,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                validator: (v) => v!.trim().isEmpty ? 'N° série requis' : null,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Numéro de série *',
                  hintText: 'ex: ECH-2025-001',
                  prefixIcon: const Icon(Icons.tag_outlined,
                      size: 18, color: _kTextGray),
                  filled: true,
                  fillColor: _kGreenBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kGreen, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.ligne.observationsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observations (optionnel)',
                  prefixIcon: const Icon(Icons.notes_outlined,
                      size: 18, color: _kTextGray),
                  filled: true,
                  fillColor: _kGreenBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kGreen, width: 1.5)),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WIDGETS HELPER (identiques à l'original)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitre extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Widget? action;
  const _SectionTitre({required this.titre, required this.icone, this.action});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(children: [
          Icon(icone, size: 18, color: _kGreen),
          const SizedBox(width: 8),
          Expanded(
              child: Text(titre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _kTextDark))),
          if (action != null) action!,
        ]),
      );
}

class _Carte extends StatelessWidget {
  final List<Widget> children;
  const _Carte({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icone;
  final int maxLines;
  final String? Function(String?)? validator;
  const _ChampTexte(
      {required this.controller,
      required this.label,
      required this.icone,
      this.maxLines = 1,
      this.validator});
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icone, size: 18, color: _kTextGray),
            filled: true,
            fillColor: _kGreenBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kGreen, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 1))),
      );
}

class _PickerDate extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  const _PickerDate({required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: _kGreen)),
                  child: child!));
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
              color: _kGreenBg, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: _kTextGray),
            const SizedBox(width: 10),
            Text(
                date != null
                    ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
                    : 'Date de réception',
                style: TextStyle(
                    color: date != null ? _kTextDark : _kTextGray,
                    fontSize: 14)),
            const Spacer(),
            if (date != null)
              const Icon(Icons.edit_outlined, size: 16, color: _kTextGray),
          ]),
        ),
      );
}

class _DropdownRecherche<T> extends StatelessWidget {
  final String label, hint;
  final IconData icone;
  final T? valeur;
  final List<T> items;
  final String Function(T) afficher;
  final void Function(T?)? onChanged;
  final bool enabled;
  final String? emptyText;
  const _DropdownRecherche(
      {required this.label,
      required this.icone,
      required this.valeur,
      required this.items,
      required this.afficher,
      required this.hint,
      required this.onChanged,
      this.enabled = true,
      this.emptyText});
  @override
  Widget build(BuildContext context) {
    final hasVal = valeur != null;
    return GestureDetector(
      onTap: enabled && onChanged != null ? () => _ouvrir(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: enabled ? _kGreenBg : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: hasVal ? _kGreen.withOpacity(0.5) : Colors.transparent,
                width: hasVal ? 1.5 : 1)),
        child: Row(children: [
          Icon(icone, size: 18, color: hasVal ? _kGreen : _kTextGray),
          const SizedBox(width: 10),
          Expanded(
              child: Text(hasVal ? afficher(valeur as T) : label,
                  style: TextStyle(
                      fontSize: 14,
                      color: hasVal ? _kTextDark : _kTextGray,
                      fontWeight: hasVal ? FontWeight.w500 : FontWeight.normal),
                  overflow: TextOverflow.ellipsis)),
          if (hasVal && enabled && onChanged != null)
            GestureDetector(
                onTap: () => onChanged!(null),
                child: const Icon(Icons.close, size: 16, color: _kTextGray))
          else
            Icon(enabled ? Icons.keyboard_arrow_down : Icons.lock_outline,
                size: 18, color: enabled ? _kTextGray : Colors.grey[400]),
        ]),
      ),
    );
  }

  void _ouvrir(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SheetRecherche<T>(
            label: label,
            icone: icone,
            items: items,
            afficher: afficher,
            hint: hint,
            valeurCourante: valeur,
            emptyText: emptyText ?? 'Aucun résultat',
            onSelected: (sel) {
              Navigator.pop(ctx);
              onChanged?.call(sel);
            }));
  }
}

class _SheetRecherche<T> extends StatefulWidget {
  final String label, hint, emptyText;
  final IconData icone;
  final List<T> items;
  final String Function(T) afficher;
  final T? valeurCourante;
  final void Function(T) onSelected;
  const _SheetRecherche(
      {required this.label,
      required this.icone,
      required this.items,
      required this.afficher,
      required this.hint,
      required this.valeurCourante,
      required this.emptyText,
      required this.onSelected});
  @override
  State<_SheetRecherche<T>> createState() => _SheetRechercheState<T>();
}

class _SheetRechercheState<T> extends State<_SheetRecherche<T>> {
  final _ctrl = TextEditingController();
  List<T> _f = [];
  @override
  void initState() {
    super.initState();
    _f = List.from(widget.items);
    _ctrl.addListener(() {
      final kw = _ctrl.text.toLowerCase();
      setState(() {
        _f = kw.isEmpty
            ? List.from(widget.items)
            : widget.items
                .where((i) => widget.afficher(i).toLowerCase().contains(kw))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(children: [
                  Icon(widget.icone, color: _kGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(widget.label,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark))),
                  Text('${_f.length}/${widget.items.length}',
                      style: const TextStyle(fontSize: 12, color: _kTextGray)),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                        hintText: widget.hint,
                        prefixIcon: const Icon(Icons.search,
                            color: _kTextGray, size: 20),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _ctrl.clear)
                            : null,
                        filled: true,
                        fillColor: _kGreenBg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _kGreen, width: 1.5)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10)))),
            const Divider(height: 1),
            Expanded(
                child: _f.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(widget.emptyText,
                                style: const TextStyle(
                                    color: _kTextGray, fontSize: 14))
                          ]))
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: _f.length,
                        itemBuilder: (_, i) {
                          final item = _f[i];
                          final sel = widget.valeurCourante != null &&
                              widget.afficher(widget.valeurCourante as T) ==
                                  widget.afficher(item);
                          return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                  leading: Icon(widget.icone,
                                      size: 18,
                                      color: sel ? _kGreen : _kTextGray),
                                  title: Text(widget.afficher(item),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: sel ? _kGreen : _kTextDark,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.normal)),
                                  trailing: sel
                                      ? const Icon(Icons.check_circle,
                                          color: _kGreen, size: 20)
                                      : null,
                                  tileColor:
                                      sel ? _kGreen.withOpacity(0.05) : null,
                                  onTap: () => widget.onSelected(item)));
                        })),
          ]),
        ),
      );
}

class _DropdownSimple<T> extends StatelessWidget {
  final String label;
  final IconData icone;
  final T? valeur;
  final List<T> items;
  final String Function(T) afficher;
  final void Function(T?)? onChanged;
  const _DropdownSimple(
      {required this.label,
      required this.icone,
      required this.valeur,
      required this.items,
      required this.afficher,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: valeur,
        isExpanded: true,
        hint: Text(label,
            style: const TextStyle(color: _kTextGray, fontSize: 14)),
        items: items
            .map((i) => DropdownMenuItem<T>(
                value: i,
                child: Text(afficher(i),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
            prefixIcon: Icon(icone, size: 18, color: _kTextGray),
            filled: true,
            fillColor: _kGreenBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kGreen, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
      );
}

class _LigneChargement extends StatelessWidget {
  final String message;
  const _LigneChargement(this.message);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen)),
          const SizedBox(width: 12),
          Text(message,
              style: const TextStyle(fontSize: 13, color: _kTextGray)),
        ]),
      );
}

class _BanniereErreur extends StatelessWidget {
  final String message;
  const _BanniereErreur({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200)),
        child: Row(children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ]),
      );
}
