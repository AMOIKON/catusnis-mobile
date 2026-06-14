// lib/features/vehicules/providers/vehicule_provider.dart

import 'package:flutter/foundation.dart';
import '../models/vehicule_model.dart';
import '../services/vehicule_service.dart';

class VehiculeProvider extends ChangeNotifier {
  final VehiculeService _service = VehiculeService();

  // ── Véhicules ─────────────────────────────────────────────────────────────
  List<VehiculeModel> _vehicules = [];
  List<VehiculeIncidentModel> _incidents = [];
  List<VehiculeMaintenanceModel> _maintenances = [];
  List<VehiculeAffectationModel> _affectations = [];
  List<VehiculeAlerteModel> _alertes = [];

  bool _loading = false;
  String? _error;
  int _totalVehicules = 0;
  int _page = 0;
  bool _hasMore = true;

  // ── Tab actif (0=Engins, 1=Affectations, 2=Incidents, 3=Maintenances, 4=Alertes)
  int _activeTab = 0;
  String? _keyword;
  String? _filterType;
  String? _filterStatut;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<VehiculeModel> get vehicules => _vehicules;
  List<VehiculeIncidentModel> get incidents => _incidents;
  List<VehiculeMaintenanceModel> get maintenances => _maintenances;
  List<VehiculeAffectationModel> get affectations => _affectations;
  List<VehiculeAlerteModel> get alertes => _alertes;
  bool get loading => _loading;
  String? get error => _error;
  int get total => _totalVehicules;
  int get activeTab => _activeTab;
  int get alertesExpireesCount => _alertes.where((a) => a.isExpire).length;

  void setTab(int tab) {
    _activeTab = tab;
    notifyListeners();
    charger(refresh: true);
  }

  void setKeyword(String? kw) {
    _keyword = kw;
    charger(refresh: true);
  }

  void setType(String? t) {
    _filterType = t;
    charger(refresh: true);
  }

  void setStatut(String? s) {
    _filterStatut = s;
    charger(refresh: true);
  }

  // ── Chargement principal ──────────────────────────────────────────────────
  Future<void> charger({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    _setLoading(true);
    try {
      switch (_activeTab) {
        case 0:
          await _chargerVehicules(refresh);
          break;
        case 1:
          await _chargerAffectations(refresh);
          break;
        case 2:
          await _chargerIncidents(refresh);
          break;
        case 3:
          await _chargerMaintenances(refresh);
          break;
        case 4:
          await _chargerAlertes();
          break;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _chargerVehicules(bool refresh) async {
    final result = await _service.getVehicules(
      page: _page,
      size: 20,
      type: _filterType,
      statut: _filterStatut,
      keyword: _keyword,
    );
    final items = result['items'] as List<VehiculeModel>;
    _totalVehicules = result['totalElements'] as int;
    if (refresh) {
      _vehicules = items;
    } else {
      _vehicules.addAll(items);
    }
    _hasMore = _vehicules.length < _totalVehicules;
    _page++;
  }

  Future<void> _chargerAffectations(bool refresh) async {
    final result = await _service.getAffectations(page: refresh ? 0 : _page);
    final items = result['items'] as List<VehiculeAffectationModel>;
    if (refresh)
      _affectations = items;
    else
      _affectations.addAll(items);
    _hasMore = _affectations.length < (result['totalElements'] as int);
    _page++;
  }

  Future<void> _chargerIncidents(bool refresh) async {
    final result = await _service.getIncidents(page: refresh ? 0 : _page);
    final items = result['items'] as List<VehiculeIncidentModel>;
    if (refresh)
      _incidents = items;
    else
      _incidents.addAll(items);
    _hasMore = _incidents.length < (result['totalElements'] as int);
    _page++;
  }

  Future<void> _chargerMaintenances(bool refresh) async {
    final result = await _service.getMaintenances(page: refresh ? 0 : _page);
    final items = result['items'] as List<VehiculeMaintenanceModel>;
    if (refresh)
      _maintenances = items;
    else
      _maintenances.addAll(items);
    _hasMore = _maintenances.length < (result['totalElements'] as int);
    _page++;
  }

  Future<void> _chargerAlertes() async {
    _alertes = await _service.getAlertes();
    _hasMore = false;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<bool> supprimerVehicule(int id) async {
    try {
      await _service.deleteVehicule(id);
      _vehicules.removeWhere((v) => v.id == id);
      _totalVehicules--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerIncident(int id) async {
    try {
      await _service.deleteIncident(id);
      _incidents.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerMaintenance(int id) async {
    try {
      await _service.deleteMaintenance(id);
      _maintenances.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
