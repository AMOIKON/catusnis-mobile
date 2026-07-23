// lib/features/structures/providers/structure_provider.dart

import 'package:flutter/foundation.dart';
import '../models/structure_model.dart';
import '../services/structure_service.dart';

enum LoadStatus { idle, loading, success, error }

class StructureListProvider extends ChangeNotifier {
  final StructureService _service = StructureService();

  List<StructureModel> _items = [];
  LoadStatus _status = LoadStatus.idle;
  String? _errorMessage;

  int? _filtreRegionId;
  int? _filtreDistrictId;
  String? _keyword;

  List<StructureModel> get items => _items;
  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int get totalElements => _items.length;
  bool get isLoading => _status == LoadStatus.loading;
  bool get hasError => _status == LoadStatus.error;

  Future<void> charger({bool refresh = false}) async {
    if (_status == LoadStatus.loading) return;

    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _items = await _service.getFiltered(
        regionId: _filtreRegionId,
        districtId: _filtreDistrictId,
        keyword: _keyword,
      );
      _status = LoadStatus.success;
    } catch (e) {
      _errorMessage = _parseError(e);
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void setFiltreRegion(int? regionId) {
    _filtreRegionId = regionId;
    _filtreDistrictId = null;
    charger(refresh: true);
  }

  void setFiltreDistrict(int? districtId) {
    _filtreDistrictId = districtId;
    charger(refresh: true);
  }

  void setKeyword(String? kw) {
    _keyword = (kw?.isNotEmpty == true) ? kw : null;
    charger(refresh: true);
  }

  void clearFiltres() {
    _filtreRegionId = null;
    _filtreDistrictId = null;
    _keyword = null;
    charger(refresh: true);
  }

  void ajouterItem(StructureModel item) {
    _items.insert(0, item);
    notifyListeners();
  }

  // ⚠️ Suppression non disponible : le backend n'expose pas encore
  // DELETE /api/structures-etatiques/{id}. Cette méthode reste prête
  // pour brancher dès que l'endpoint existera.
  Future<bool> supprimer(int id) async {
    try {
      await _service.delete(id);
      _items.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  String _parseError(Object e) =>
      e.toString().replaceAll('Exception:', '').trim();
}
