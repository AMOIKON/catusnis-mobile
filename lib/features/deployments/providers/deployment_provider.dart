// lib/features/deployments/providers/deployment_provider.dart

import 'package:flutter/material.dart';
import '../models/deployment_model.dart';
import '../services/deployment_service.dart';

enum LoadStatus { idle, loading, success, error }

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER LISTE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentListProvider extends ChangeNotifier {
  final DeploymentService _service;
  DeploymentListProvider({DeploymentService? service})
      : _service = service ?? DeploymentService();

  List<DeploymentModel> _items = [];
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  int _totalElements = 0;
  int _currentPage = 0;
  bool _hasMore = true;

  String? _filtreStatut;
  int? _filtreRegionId;
  String? _keyword;

  List<DeploymentModel> get items => _items;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;
  bool get isLoading => _status == LoadStatus.loading;
  bool get hasError => _status == LoadStatus.error;
  String? get filtreStatut => _filtreStatut;
  int? get filtreRegionId => _filtreRegionId;
  String? get keyword => _keyword;

  Future<void> charger({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _items = [];
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;
    if (_status == LoadStatus.loading) return;

    _setStatus(LoadStatus.loading);
    try {
      final result = await _service.getDeployments(
        page: _currentPage,
        size: 20,
        statut: _filtreStatut,
        regionId: _filtreRegionId,
        keyword: _keyword,
      );
      final nouveaux = result['items'] as List<DeploymentModel>;
      _totalElements = result['totalElements'] as int;
      if (refresh) {
        _items = nouveaux;
      } else {
        _items.addAll(nouveaux);
      }
      _hasMore = _items.length < _totalElements;
      _currentPage++;
      _setStatus(LoadStatus.success);
    } catch (e) {
      _errorMessage = _parseError(e);
      _setStatus(LoadStatus.error);
    }
  }

  Future<void> chargerPlus() => charger();

  void setFiltreStatut(String? statut) {
    _filtreStatut = statut;
    charger(refresh: true);
  }

  void setFiltreRegion(int? regionId) {
    _filtreRegionId = regionId;
    charger(refresh: true);
  }

  void setKeyword(String? kw) {
    _keyword = kw?.isNotEmpty == true ? kw : null;
    charger(refresh: true);
  }

  void clearFiltres() {
    _filtreStatut = null;
    _filtreRegionId = null;
    _keyword = null;
    charger(refresh: true);
  }

  bool get filtresActifs =>
      _filtreStatut != null || _filtreRegionId != null || _keyword != null;

  void mettreAJourItem(DeploymentModel updated) {
    final idx = _items.indexWhere((d) => d.id == updated.id);
    if (idx != -1) {
      _items[idx] = updated;
      notifyListeners();
    }
  }

  void supprimerItemLocal(int id) {
    _items.removeWhere((d) => d.id == id);
    _totalElements = (_totalElements - 1).clamp(0, _totalElements);
    notifyListeners();
  }

  void ajouterItem(DeploymentModel item) {
    _items.insert(0, item);
    _totalElements++;
    notifyListeners();
  }

  Future<bool> supprimer(int id) async {
    try {
      await _service.deleteDeployment(id);
      supprimerItemLocal(id);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiver(int id) async {
    try {
      final updated = await _service.archiveDeployment(id);
      mettreAJourItem(updated);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void _setStatus(LoadStatus s) {
    _status = s;
    notifyListeners();
  }

  String _parseError(Object e) =>
      e.toString().replaceAll('Exception:', '').trim();
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER FICHE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentFicheProvider extends ChangeNotifier {
  final DeploymentService _service;
  DeploymentFicheProvider({DeploymentService? service})
      : _service = service ?? DeploymentService();

  DeploymentModel? _fiche;
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;
  bool _archivageEnCours = false;
  bool _pdfEnCours = false;

  DeploymentModel? get fiche => _fiche;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LoadStatus.loading;
  bool get hasError => _status == LoadStatus.error;
  bool get archivageEnCours => _archivageEnCours;
  bool get pdfEnCours => _pdfEnCours;

  Future<void> charger(int id) async {
    if (id == -1) {
      _fiche = DeploymentModel.samples.first;
      _status = LoadStatus.success;
      notifyListeners();
      return;
    }
    _setStatus(LoadStatus.loading);
    try {
      _fiche = await _service.getDeployment(id);
      _setStatus(LoadStatus.success);
    } catch (e) {
      _errorMessage = _parseError(e);
      _setStatus(LoadStatus.error);
    }
  }

  Future<bool> archiver() async {
    if (_fiche == null) return false;
    _archivageEnCours = true;
    notifyListeners();
    try {
      _fiche = await _service.archiveDeployment(_fiche!.id);
      _archivageEnCours = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _archivageEnCours = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changerStatut(String statut) async {
    if (_fiche == null) return false;
    try {
      _fiche = await _service.updateStatut(_fiche!.id, statut);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void toggleReceptionItem(int itemId) {
    if (_fiche == null) return;
    final items = _fiche!.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(receptionConfirm: !item.receptionConfirm);
      }
      return item;
    }).toList();
    _fiche = _fiche!.copyWith(items: items);
    notifyListeners();
  }

  void setPdfEnCours(bool val) {
    _pdfEnCours = val;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_fiche != null) await charger(_fiche!.id);
  }

  void reset() {
    _fiche = null;
    _status = LoadStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setStatus(LoadStatus s) {
    _status = s;
    notifyListeners();
  }

  String _parseError(Object e) =>
      e.toString().replaceAll('Exception:', '').trim();
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER FORMULAIRE
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentFormProvider extends ChangeNotifier {
  final DeploymentService _service;
  DeploymentFormProvider({DeploymentService? service})
      : _service = service ?? DeploymentService();

  // Données de référence
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _healths = [];
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _partners = [];

  // Sélections
  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedHealth;
  Map<String, dynamic>? _selectedApp;
  Map<String, dynamic>? _selectedPartnerPrincipal;
  Map<String, dynamic>? _selectedPartnerSecondaire;

  // Équipements
  final List<EquipementLigne> _equipementLignes = [];

  // États
  bool _loadingRef = false;
  bool _loadingDistricts = false;
  bool _loadingHealths = false;
  bool _submitting = false;
  String? _errorMessage;

  DeploymentModel? _deploymentEnEdition;
  bool get isEdit => _deploymentEnEdition != null;

  // Getters
  List<Map<String, dynamic>> get regions => _regions;
  List<Map<String, dynamic>> get districts => _districts;
  List<Map<String, dynamic>> get healths => _healths;
  List<Map<String, dynamic>> get apps => _apps;
  List<Map<String, dynamic>> get partners => _partners;

  Map<String, dynamic>? get selectedRegion => _selectedRegion;
  Map<String, dynamic>? get selectedDistrict => _selectedDistrict;
  Map<String, dynamic>? get selectedHealth => _selectedHealth;
  Map<String, dynamic>? get selectedApp => _selectedApp;
  Map<String, dynamic>? get selectedPartnerPrincipal =>
      _selectedPartnerPrincipal;
  Map<String, dynamic>? get selectedPartnerSecondaire =>
      _selectedPartnerSecondaire;

  List<EquipementLigne> get equipementLignes => _equipementLignes;
  bool get loadingRef => _loadingRef;
  bool get loadingDistricts => _loadingDistricts;
  bool get loadingHealths => _loadingHealths;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialiser({DeploymentModel? deploymentExistant}) async {
    _loadingRef = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _service.loadFormData();
      _regions = data.regions;
      _apps = data.apps;
      _partners = data.partners;

      if (deploymentExistant != null) {
        await _preselecterPourEdition(deploymentExistant);
      } else {
        if (_equipementLignes.isEmpty) {
          _equipementLignes.add(EquipementLigne());
        }
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _loadingRef = false;
      notifyListeners();
    }
  }

  Future<void> _preselecterPourEdition(DeploymentModel dep) async {
    _deploymentEnEdition = dep;

    _selectedApp = _apps.where((a) => a['id'] == dep.app?.id).firstOrNull;

    _selectedPartnerPrincipal =
        _partners.where((p) => p['id'] == dep.partnerPrincipal?.id).firstOrNull;

    _selectedPartnerSecondaire = _partners
        .where((p) => p['id'] == dep.partnerSecondaire?.id)
        .firstOrNull;

    if (dep.regionId != null) {
      _selectedRegion =
          _regions.where((r) => r['id'] == dep.regionId).firstOrNull;
      if (_selectedRegion != null) {
        await _chargerDistricts(dep.regionId!, preselectId: dep.districtId);
      }
    }

    _equipementLignes.clear();
    for (final item in dep.items) {
      _equipementLignes.add(EquipementLigne.fromItem(item));
    }
    if (_equipementLignes.isEmpty) _equipementLignes.add(EquipementLigne());
  }

  // ── Sélecteurs cascadés ───────────────────────────────────────────────────

  Future<void> selectionnerRegion(Map<String, dynamic>? region) async {
    _selectedRegion = region;
    _selectedDistrict = null;
    _selectedHealth = null;
    _districts = [];
    _healths = [];
    notifyListeners();
    if (region == null) return;
    await _chargerDistricts(region['id'] as int);
  }

  Future<void> _chargerDistricts(int regionId, {int? preselectId}) async {
    _loadingDistricts = true;
    notifyListeners();
    try {
      _districts = await _service.getDistricts(regionId);
      if (preselectId != null) {
        _selectedDistrict =
            _districts.where((d) => d['id'] == preselectId).firstOrNull;
        if (_selectedDistrict != null) {
          await _chargerHealths(preselectId,
              preselectHealthId: _deploymentEnEdition?.healthId);
        }
      }
    } catch (_) {
      _districts = [];
    } finally {
      _loadingDistricts = false;
      notifyListeners();
    }
  }

  Future<void> selectionnerDistrict(Map<String, dynamic>? district) async {
    _selectedDistrict = district;
    _selectedHealth = null;
    _healths = [];
    notifyListeners();
    if (district == null) return;
    await _chargerHealths(district['id'] as int);
  }

  Future<void> _chargerHealths(int districtId, {int? preselectHealthId}) async {
    _loadingHealths = true;
    notifyListeners();
    try {
      _healths = await _service.getHealths(districtId);
      if (preselectHealthId != null) {
        _selectedHealth =
            _healths.where((h) => h['id'] == preselectHealthId).firstOrNull;
      }
    } catch (_) {
      _healths = [];
    } finally {
      _loadingHealths = false;
      notifyListeners();
    }
  }

  void selectionnerHealth(Map<String, dynamic>? health) {
    _selectedHealth = health;
    notifyListeners();
  }

  void selectionnerApp(Map<String, dynamic>? app) {
    _selectedApp = app;
    notifyListeners();
  }

  void selectionnerPartnerPrincipal(Map<String, dynamic>? p) {
    _selectedPartnerPrincipal = p;
    if (_selectedPartnerSecondaire?['id'] == p?['id']) {
      _selectedPartnerSecondaire = null;
    }
    notifyListeners();
  }

  void selectionnerPartnerSecondaire(Map<String, dynamic>? p) {
    _selectedPartnerSecondaire = p;
    if (_selectedPartnerPrincipal?['id'] == p?['id']) {
      _selectedPartnerPrincipal = null;
    }
    notifyListeners();
  }

  // ── Lignes équipements ────────────────────────────────────────────────────

  void ajouterLigne() {
    _equipementLignes.add(EquipementLigne());
    notifyListeners();
  }

  void supprimerLigne(int index) {
    if (_equipementLignes.length <= 1) return;
    _equipementLignes[index].dispose();
    _equipementLignes.removeAt(index);
    notifyListeners();
  }

  void mettreAJourTypeLigne(int index, String? typeName, String? designation) {
    if (index < _equipementLignes.length) {
      _equipementLignes[index].typeName = typeName;
      _equipementLignes[index].designation = designation;
      notifyListeners();
    }
  }

  String? validerEquipements() {
    for (int i = 0; i < _equipementLignes.length; i++) {
      final l = _equipementLignes[i];
      if (l.typeName == null || l.typeName!.isEmpty) {
        return 'Ligne ${i + 1} : veuillez sélectionner un type';
      }
      if (l.numeroSerieCtrl.text.trim().isEmpty) {
        return 'Ligne ${i + 1} : numéro de série requis';
      }
    }
    return null;
  }

  // ── Soumission ────────────────────────────────────────────────────────────

  Future<DeploymentModel?> soumettre(
    String codeDep,
    String? dateReception,
    String? observations,
  ) async {
    if (_selectedRegion == null ||
        _selectedDistrict == null ||
        _selectedHealth == null) {
      _errorMessage = 'Veuillez sélectionner la région, le district et le site';
      notifyListeners();
      return null;
    }

    final errEq = validerEquipements();
    if (errEq != null) {
      _errorMessage = errEq;
      notifyListeners();
      return null;
    }

    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    final body = _construireBody(codeDep, dateReception, observations);

    try {
      final result = isEdit
          ? await _service.updateDeployment(_deploymentEnEdition!.id, body)
          : await _service.createDeployment(body);
      _submitting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = _parseError(e);
      _submitting = false;
      notifyListeners();
      return null;
    }
  }

  // ── _construireBody ───────────────────────────────────────────────────────
  //
  // DeploymentRequest.java :
  //   @NotBlank  String        codeDep
  //   @NotNull   LocalDateTime dateRecep   ← jamais null, fallback = today
  //              String        comment
  //   @NotNull   Integer       regionId
  //   @NotNull   Integer       districtId
  //   @NotNull   Integer       healthId
  //              Integer       appsId
  //              Integer       partnerId
  //   List<DeploymentItemRequest> items → { acquisitionId, status }

  Map<String, dynamic> _construireBody(
    String codeDep,
    String? dateReception,
    String? observations,
  ) {
    // ✅ dateRecep est @NotNull — on garantit toujours une valeur
    final String dateRecep;
    if (dateReception != null && dateReception.isNotEmpty) {
      // "2025-01-12" → "2025-01-12T00:00:00"
      dateRecep = dateReception.contains('T')
          ? dateReception
          : '${dateReception}T00:00:00';
    } else {
      // Fallback : date du jour
      final now = DateTime.now();
      final y = now.year;
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      dateRecep = '${y}-${m}-${d}T00:00:00';
    }

    return {
      'codeDep': codeDep,
      'dateRecep': dateRecep,
      'comment': observations,
      'regionId': _selectedRegion!['id'],
      'districtId': _selectedDistrict!['id'],
      'healthId': _selectedHealth!['id'],
      'appsId': _selectedApp?['id'],
      'partnerId': _selectedPartnerPrincipal?['id'],
      'items': _equipementLignes
          .map((l) => {
                'acquisitionId': l.acquisitionId,
                'status': l.statut ?? 'FONCTIONNEL',
              })
          .toList(),
    };
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    for (final l in _equipementLignes) {
      l.dispose();
    }
    _equipementLignes.clear();
    _selectedRegion = null;
    _selectedDistrict = null;
    _selectedHealth = null;
    _selectedApp = null;
    _selectedPartnerPrincipal = null;
    _selectedPartnerSecondaire = null;
    _districts = [];
    _healths = [];
    _deploymentEnEdition = null;
    _errorMessage = null;
    _submitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final l in _equipementLignes) {
      l.dispose();
    }
    super.dispose();
  }

  String _parseError(Object e) =>
      e.toString().replaceAll('Exception:', '').trim();
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIGNE ÉQUIPEMENT
// ─────────────────────────────────────────────────────────────────────────────

class EquipementLigne {
  String? typeName;
  String? designation;
  String? statut;
  int? acquisitionId;

  final TextEditingController numeroSerieCtrl;
  final TextEditingController observationsCtrl;

  EquipementLigne({
    this.typeName,
    this.designation,
    this.statut,
    this.acquisitionId,
    String numeroSerie = '',
    String observations = '',
  })  : numeroSerieCtrl = TextEditingController(text: numeroSerie),
        observationsCtrl = TextEditingController(text: observations);

  factory EquipementLigne.fromItem(DeploymentItem item) => EquipementLigne(
        typeName: item.typeName,
        designation: item.designation,
        statut: item.statut,
        acquisitionId: item.id,
        numeroSerie: item.numeroSerie,
        observations: item.observations ?? '',
      );

  void dispose() {
    numeroSerieCtrl.dispose();
    observationsCtrl.dispose();
  }
}
