// lib/features/booklets/services/booklet_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/booklet_model.dart';

class BookletService {
  final DioClient _client = DioClient();

  // ── Tous les booklets ─────────────────────────────────────────────────────
  Future<List<BookletModel>> getAll() async {
    final response = await _client.get(ApiConstants.BOOKLETS);
    return _parseList(response.data);
  }

  // ── Recherche ─────────────────────────────────────────────────────────────
  Future<List<BookletModel>> search(String keyword) async {
    final response = await _client.get(
      '${ApiConstants.BOOKLETS}/search',
      params: {'keyword': keyword},
    );
    return _parseList(response.data);
  }

  // ── Par région ────────────────────────────────────────────────────────────
  Future<List<BookletModel>> getByRegion(int regionId) async {
    final response = await _client.get(
      '${ApiConstants.BOOKLETS}/region/$regionId',
    );
    return _parseList(response.data);
  }

  // ── Par district ──────────────────────────────────────────────────────────
  Future<List<BookletModel>> getByDistrict(int districtId) async {
    final response = await _client.get(
      '${ApiConstants.BOOKLETS}/district/$districtId',
    );
    return _parseList(response.data);
  }

  // ── Stats par statut ──────────────────────────────────────────────────────
  Future<Map<String, int>> getStats() async {
    try {
      final response = await _client.get('${ApiConstants.BOOKLETS}/stats');
      final raw = response.data;
      final map = raw is Map ? raw : (raw['data'] as Map? ?? {});
      return map.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ── Statuts disponibles ───────────────────────────────────────────────────
  Future<List<BookletStatusModel>> getStatuses() async {
    try {
      final response = await _client.get('/api/booklet-status');
      final raw = response.data;
      List<dynamic> list = raw is List ? raw : (raw['data'] as List? ?? []);
      return list
          .whereType<Map<String, dynamic>>()
          .map(BookletStatusModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  List<BookletModel> _parseList(dynamic raw) {
    List<dynamic> list = [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final data = raw['data'];
      if (data is List) list = data;
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(BookletModel.fromJson)
        .toList();
  }
}
