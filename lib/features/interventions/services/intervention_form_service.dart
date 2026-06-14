// lib/features/interventions/services/intervention_form_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';

class InterventionFormService {
  static final InterventionFormService _instance =
      InterventionFormService._internal();
  factory InterventionFormService() => _instance;
  InterventionFormService._internal();

  final DioClient _dio = DioClient();

  // ── Déploiements ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDeployments() async {
    final response = await _dio.get(ApiConstants.DEPLOYMENTS,
        params: {'page': 0, 'size': 100, 'sort': 'id,desc'});
    return List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
  }

  // ── Évaluations ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEvaluations() async {
    final response =
        await _dio.get('/api/evaluations', params: {'page': 0, 'size': 50});
    return List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
  }

  // ── Types équipements ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTypes() async {
    final response =
        await _dio.get('/api/types', params: {'page': 0, 'size': 100});
    return List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
  }

  // ── Applications ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getApps() async {
    final response =
        await _dio.get('/api/apps', params: {'page': 0, 'size': 50});
    final raw = response.data['data'];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return List<Map<String, dynamic>>.from(raw['content'] as List);
  }

  // ── Items d'un déploiement ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDeploymentItems(
      int deploymentId) async {
    final response =
        await _dio.get('${ApiConstants.DEPLOYMENTS}/$deploymentId');
    final items = response.data['data']['items'] as List? ?? [];
    return List<Map<String, dynamic>>.from(items);
  }

  // ── Créer une intervention ────────────────────────────────────────────────
  Future<Map<String, dynamic>> createIntervention(
      Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.INTERVENTIONS, data: body);
    return response.data['data'] as Map<String, dynamic>;
  }
}
