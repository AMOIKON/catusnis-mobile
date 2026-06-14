// lib/features/interventions/services/intervention_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/intervention_model.dart';

class InterventionService {
  static final InterventionService _instance = InterventionService._internal();
  factory InterventionService() => _instance;
  InterventionService._internal();

  final DioClient _dio = DioClient();

  Future<Map<String, dynamic>> getInterventions({
    int page = 0,
    int size = 10,
    int? regionId,
    int? districtId,
    int? healthId,
    String? keyword,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': 'id,desc',
    };
    if (regionId != null) params['regionId'] = regionId;
    if (districtId != null) params['districtId'] = districtId;
    if (healthId != null) params['healthId'] = healthId;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await _dio.get(ApiConstants.INTERVENTIONS, params: params);
    final data = response.data['data'];
    return {
      'items': (data['content'] as List)
          .map((e) => InterventionModel.fromJson(e))
          .toList(),
      'totalElements': data['page']['totalElements'] ?? 0,
      'totalPages': data['page']['totalPages'] ?? 0,
    };
  }

  // ── Supprimer une intervention ───────────────────────────────────
  Future<void> deleteIntervention(int id) async {
    await _dio.delete('${ApiConstants.INTERVENTIONS}/$id');
  }
}
