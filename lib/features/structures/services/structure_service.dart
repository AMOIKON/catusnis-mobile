// lib/features/structures/services/structure_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/structure_model.dart';

class StructureService {
  final DioClient _client = DioClient();

  /// Backend actuel : GET /api/structures-etatiques renvoie une liste
  /// simple (pas de pagination).
  Future<List<StructureModel>> getAllList() async {
    final response = await _client.get(ApiConstants.STRUCTURES_ETATIQUES);
    final raw = response.data;
    final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

    final list = (data is List) ? data : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(StructureModel.fromJson)
        .toList();
  }

  /// Filtrage local (région/district/mot-clé) — tant que le backend
  /// n'a pas d'endpoint de recherche dédié.
  Future<List<StructureModel>> getFiltered({
    int? regionId,
    int? districtId,
    String? keyword,
  }) async {
    final all = await getAllList();
    return all.where((s) {
      final matchRegion = regionId == null || s.regionId == regionId;
      final matchDistrict = districtId == null || s.districtId == districtId;
      final matchKeyword = keyword == null ||
          keyword.isEmpty ||
          s.nom.toLowerCase().contains(keyword.toLowerCase());
      return matchRegion && matchDistrict && matchKeyword;
    }).toList();
  }

  /// ✅ Disponible depuis l'ajout de GET /structures-etatiques/{id}
  Future<StructureModel> getById(int id) async {
    final response =
        await _client.get('${ApiConstants.STRUCTURES_ETATIQUES}/$id');
    final raw = response.data;
    final map = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return StructureModel.fromJson(map);
  }

  Future<StructureModel> create(Map<String, dynamic> body) async {
    final response =
        await _client.post(ApiConstants.STRUCTURES_ETATIQUES, data: body);
    final raw = response.data;
    final map = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return StructureModel.fromJson(map);
  }

  /// ✅ Disponible depuis l'ajout de PUT /structures-etatiques/{id}
  Future<StructureModel> update(int id, Map<String, dynamic> body) async {
    final response = await _client.put(
      '${ApiConstants.STRUCTURES_ETATIQUES}/$id',
      data: body,
    );
    final raw = response.data;
    final map = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return StructureModel.fromJson(map);
  }

  /// ✅ Disponible depuis l'ajout de DELETE /structures-etatiques/{id}
  Future<void> delete(int id) async {
    await _client.delete('${ApiConstants.STRUCTURES_ETATIQUES}/$id');
  }
}
