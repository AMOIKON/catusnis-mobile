// lib/features/booklets/providers/booklet_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/services/CacheService.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/booklet_model.dart';
import '../services/booklet_service.dart';

enum BookletStatus { idle, loading, loaded, error }

class BookletProvider extends ChangeNotifier {
  final BookletService _service = BookletService();
  final CacheService _cache = CacheService();
  final ConnectivityService _conn = ConnectivityService();
  // ✅ _sync supprimé — non utilisé dans ce provider

  BookletStatus _status = BookletStatus.idle;
  List<BookletModel> _items = [];
  List<BookletStatusModel> _statuses = [];
  Map<String, int> _stats = {};
  String? _error;
  String? _filtreStatut;
  bool _fromCache = false;
  DateTime? _cachedAt;

  BookletStatus get status => _status;
  List<BookletModel> get items => _items;
  List<BookletStatusModel> get statuses => _statuses;
  Map<String, int> get stats => _stats;
  String? get error => _error;
  String? get filtreStatut => _filtreStatut;
  bool get isLoading => _status == BookletStatus.loading;
  bool get hasError => _status == BookletStatus.error;
  bool get isOffline => _conn.isOffline;
  bool get fromCache => _fromCache;
  DateTime? get cachedAt => _cachedAt;

  List<BookletModel> get filtered => _filtreStatut == null
      ? _items
      : _items.where((b) => b.statusName == _filtreStatut).toList();

  Map<String, List<BookletModel>> get groupedByRegion {
    final map = <String, List<BookletModel>>{};
    for (final b in filtered) {
      map.putIfAbsent(b.regionName ?? 'Non défini', () => []).add(b);
    }
    return Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );
  }

  Future<void> charger({bool refresh = false}) async {
    if (_status == BookletStatus.loading) return;
    if (!refresh && _status == BookletStatus.loaded) return;

    _status = BookletStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _cache.loadList(
        cacheKey: CacheService.kBooklets,
        fetchFromNetwork: () async {
          final all = await _service.getAll();
          return all.map(_bookletToMap).toList();
        },
        ttl: const Duration(hours: 12),
      );

      _items = result.items.map(BookletModel.fromJson).toList();
      _fromCache = result.fromCache;
      _cachedAt = result.cachedAt;

      final statusResult = await _cache.loadList(
        cacheKey: CacheService.kBookletStatuses,
        fetchFromNetwork: () async {
          final statuses = await _service.getStatuses();
          return statuses
              .map((s) => {'id': s.id, 'statusName': s.statusName})
              .toList();
        },
        ttl: const Duration(hours: 48),
      );
      _statuses = statusResult.items.map(BookletStatusModel.fromJson).toList();

      _stats =
          _conn.isOnline ? await _service.getStats() : _computeLocalStats();

      _status = BookletStatus.loaded;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = BookletStatus.error;
      debugPrint('❌ BookletProvider: $_error');
    }
    notifyListeners();
  }

  void setFiltreStatut(String? statut) {
    _filtreStatut = statut;
    notifyListeners();
  }

  int countByStatut(String statusName) =>
      _items.where((b) => b.statusName == statusName).length;

  Future<void> invalidateCache() async {
    await _cache.invalidate(CacheService.kBooklets);
    await charger(refresh: true);
  }

  Map<String, int> _computeLocalStats() {
    final result = <String, int>{};
    for (final b in _items) {
      final s = b.statusName ?? 'Inconnu';
      result[s] = (result[s] ?? 0) + 1;
    }
    return result;
  }

  Map<String, dynamic> _bookletToMap(BookletModel b) => {
        'id': b.id,
        'firstName': b.firstName,
        'lastName': b.lastName,
        'contact': b.contact,
        'email': b.email,
        'region': b.regionId != null
            ? {'id': b.regionId, 'regionName': b.regionName}
            : null,
        'district': b.districtId != null
            ? {'id': b.districtId, 'districtName': b.districtName}
            : null,
        'post':
            b.postId != null ? {'id': b.postId, 'postName': b.postName} : null,
        'status': b.statusId != null
            ? {'id': b.statusId, 'statusName': b.statusName}
            : null,
      };
}
