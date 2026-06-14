// lib/features/fournitures/providers/fourniture_provider.dart

import 'package:flutter/foundation.dart';
import '../models/fourniture_model.dart';
import '../services/fourniture_service.dart';

class FournitureProvider extends ChangeNotifier {
  final FournitureService _service = FournitureService();

  List<FournitureModel> _fournitures = [];
  List<FournitureDeploiementModel> _deploiements = [];
  FournitureStats _stats = FournitureStats.empty();

  bool _loading = false;
  String? _error;
  int _total = 0;
  int _page = 0;
  bool _hasMore = true;

  // Tab : 0=Articles, 1=Déploiements, 2=Historique
  int _activeTab = 0;
  String? _keyword;
  String? _filterCategorie;
  String? _filterStatut;
  bool? _filterActif;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<FournitureModel> get fournitures => _fournitures;
  List<FournitureDeploiementModel> get deploiements => _deploiements;
  FournitureStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  int get total => _total;
  int get activeTab => _activeTab;

  void setTab(int t) {
    _activeTab = t;
    charger(refresh: true);
  }

  void setKeyword(String? kw) {
    _keyword = kw;
    charger(refresh: true);
  }

  void setCategorie(String? c) {
    _filterCategorie = c;
    charger(refresh: true);
  }

  void setStatut(String? s) {
    _filterStatut = s;
    charger(refresh: true);
  }

  void setActif(bool? a) {
    _filterActif = a;
    charger(refresh: true);
  }

  Future<void> charger({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;
    _setLoading(true);
    _error = null;
    try {
      if (_activeTab == 0) {
        await _chargerFournitures(refresh);
      } else {
        await _chargerDeploiements(refresh);
      }
      if (refresh) await _chargerStats();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _chargerFournitures(bool refresh) async {
    final res = await _service.getFournitures(
      page: _page,
      size: 20,
      categorie: _filterCategorie,
      statut: _filterStatut,
      keyword: _keyword,
    );
    final items = res['items'] as List<FournitureModel>;
    _total = res['totalElements'] as int;
    if (refresh)
      _fournitures = items;
    else
      _fournitures.addAll(items);
    _hasMore = _fournitures.length < _total;
    _page++;
  }

  Future<void> _chargerDeploiements(bool refresh) async {
    final res = await _service.getDeploiements(
      page: refresh ? 0 : _page,
      active: _filterActif,
      keyword: _keyword,
    );
    final items = res['items'] as List<FournitureDeploiementModel>;
    if (refresh)
      _deploiements = items;
    else
      _deploiements.addAll(items);
    _hasMore = _deploiements.length < (res['totalElements'] as int);
    _page++;
  }

  Future<void> _chargerStats() async {
    _stats = await _service.getStats();
  }

  Future<bool> supprimerFourniture(int id) async {
    try {
      await _service.deleteFourniture(id);
      _fournitures.removeWhere((f) => f.id == id);
      _total--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cloturerDeploiement(int id) async {
    try {
      await _service.cloturerDeploiement(id);
      charger(refresh: true);
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
