// lib/features/deployments/services/deployment_form_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';

class DeploymentFormService {
  static final DeploymentFormService _instance =
      DeploymentFormService._internal();
  factory DeploymentFormService() => _instance;
  DeploymentFormService._internal();

  final DioClient _dio = DioClient();

  // ── Régions ───────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRegions() async {
    final response =
        await _dio.get('/api/regions', params: {'page': 0, 'size': 100});
    return List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
  }

  // ── Districts par région ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDistricts(int regionId) async {
    final response = await _dio.get('/api/districts',
        params: {'regionId': regionId, 'page': 0, 'size': 100});
    return List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
  }

  // ── Sites par district ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getHealths(int districtId) async {
    final response = await _dio.get(ApiConstants.HEALTHS,
        params: {'districtId': districtId, 'page': 0, 'size': 200});
    return List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
  }

  // ── Applications ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getApps() async {
    final response =
        await _dio.get('/api/apps', params: {'page': 0, 'size': 50});
    // Essaie data.content d'abord, sinon data directement
    final raw = response.data['data'];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return List<Map<String, dynamic>>.from(raw['content'] as List);
  }

  // ── Partenaires ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPartners() async {
    final response =
        await _dio.get('/api/partners', params: {'page': 0, 'size': 50});
    final raw = response.data['data'];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return List<Map<String, dynamic>>.from(raw['content'] as List);
  }

  // ── Acquisitions disponibles ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAvailableAcquisitions() async {
    final response = await _dio.get('/api/acquisitions/available');
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }

  // ── Créer un déploiement ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> createDeployment(
      Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.DEPLOYMENTS, data: body);
    return response.data['data'] as Map<String, dynamic>;
  }
}
