// lib/features/technician_sites/providers/technician_site_provider.dart

import 'package:flutter/foundation.dart';
import '../models/technician_site.dart';
import '../services/technician_site_service.dart';

enum TechnicianSiteStatus { idle, loading, loaded, error }

class TechnicianSiteProvider extends ChangeNotifier {
  final TechnicianSiteService _service = TechnicianSiteService();

  // ── État ──────────────────────────────────────────────────────────────────
  TechnicianSiteStatus _status = TechnicianSiteStatus.idle;
  List<TechnicianSite> _assignments = [];
  String? _error;
  int? _currentPersonId;
  bool _isDeleting = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  TechnicianSiteStatus get status => _status;
  List<TechnicianSite> get assignments => _assignments;
  String? get error => _error;
  int? get currentPersonId => _currentPersonId;
  bool get isDeleting => _isDeleting;

  List<RegionNode> get tree => buildTree(_assignments);

  int get totalRegions => {
        ..._assignments.where((a) => a.regionId != null).map((a) => a.regionId)
      }.length;
  int get totalDistricts => {
        ..._assignments
            .where((a) => a.districtId != null)
            .map((a) => a.districtId)
      }.length;
  int get totalSites => {
        ..._assignments.where((a) => a.healthId != null).map((a) => a.healthId)
      }.length;

  // ── Charger les assignations ──────────────────────────────────────────────
  Future<void> loadByPerson(int personId) async {
    if (_currentPersonId == personId && _status == TechnicianSiteStatus.loaded)
      return;

    _status = TechnicianSiteStatus.loading;
    _currentPersonId = personId;
    _error = null;
    notifyListeners();

    try {
      _assignments = await _service.getByTechnician(personId);
      _status = TechnicianSiteStatus.loaded;
    } catch (e) {
      _error = _extractError(e);
      _status = TechnicianSiteStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentPersonId == null) return;
    _status = TechnicianSiteStatus.loading;
    notifyListeners();
    try {
      _assignments = await _service.getByTechnician(_currentPersonId!);
      _status = TechnicianSiteStatus.loaded;
    } catch (e) {
      _error = _extractError(e);
      _status = TechnicianSiteStatus.error;
    }
    notifyListeners();
  }

  // ── Supprimer ─────────────────────────────────────────────────────────────
  Future<bool> unassign(int id) async {
    _isDeleting = true;
    notifyListeners();
    try {
      await _service.unassign(id);
      _assignments.removeWhere((a) => a.id == id);
      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  void clearForPerson() {
    _assignments = [];
    _currentPersonId = null;
    _status = TechnicianSiteStatus.idle;
    _error = null;
    notifyListeners();
  }

  String _extractError(Object e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return e.toString();
  }
}
