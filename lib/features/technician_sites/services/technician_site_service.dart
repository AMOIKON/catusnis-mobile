// lib/features/technician_sites/services/technician_site_service.dart

import '../../../core/api/dio_client.dart';
import '../models/technician_site.dart';

class TechnicianSiteService {
  final DioClient _client = DioClient();

  static const String _base = '/api/technician-sites';

  // ── Récupérer les assignations d'un technicien / logisticien ──────────────
  Future<List<TechnicianSite>> getByTechnician(int personId) async {
    final response = await _client.get('$_base/technician/$personId');
    final list = _extractList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(TechnicianSite.fromJson)
        .toList();
  }

  // ── Assigner un périmètre ─────────────────────────────────────────────────
  Future<TechnicianSite> assign({
    required int personId,
    int? regionId,
    int? districtId,
    int? healthId,
  }) async {
    final response = await _client.post(
      _base,
      data: {
        'personId': personId,
        if (regionId != null) 'regionId': regionId,
        if (districtId != null) 'districtId': districtId,
        if (healthId != null) 'healthId': healthId,
      },
    );
    final raw = response.data;
    final map = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return TechnicianSite.fromJson(map);
  }

  // ── Supprimer une assignation ─────────────────────────────────────────────
  Future<void> unassign(int id) async {
    await _client.delete('$_base/$id');
  }

  // ── IDs utilitaires ───────────────────────────────────────────────────────
  Future<List<int>> getHealthIds(int personId) async {
    final response = await _client.get(
      '$_base/technician/$personId/health-ids',
    );
    return _extractList(response.data).whereType<int>().toList();
  }

  Future<List<int>> getRegionIds(int personId) async {
    final response = await _client.get(
      '$_base/technician/$personId/region-ids',
    );
    return _extractList(response.data).whereType<int>().toList();
  }

  // ── Helper extraction liste ───────────────────────────────────────────────
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    if (raw is Map && raw['data'] is Map) {
      final content = (raw['data'] as Map)['content'];
      if (content is List) return content;
    }
    return [];
  }
}
