// lib/features/deployments/services/deployment_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../models/deployment_model.dart';

class DeploymentService {
  static final DeploymentService _instance = DeploymentService._internal();
  factory DeploymentService() => _instance;
  DeploymentService._internal();

  final DioClient _dio = DioClient();

  // ─────────────────────────────────────────────────────────────────────────
  //  LISTE PAGINÉE
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDeployments({
    int page = 0,
    int size = 20,
    String sort = 'id,desc',
    String? statut,
    int? regionId,
    int? districtId,
    int? healthId,
    String? keyword,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': sort,
    };
    if (statut != null) params['statut'] = statut;
    if (regionId != null) params['regionId'] = regionId;
    if (districtId != null) params['districtId'] = districtId;
    if (healthId != null) params['healthId'] = healthId;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await _dio.get(ApiConstants.DEPLOYMENTS, params: params);
    final data = response.data['data'];

    return {
      'items': (data['content'] as List<dynamic>)
          .map((e) => DeploymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'totalElements': (data['page']['totalElements'] as num?)?.toInt() ?? 0,
      'totalPages': (data['page']['totalPages'] as num?)?.toInt() ?? 0,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FICHE COMPLÈTE
  // ─────────────────────────────────────────────────────────────────────────

  Future<DeploymentModel> getDeployment(int id) async {
    final response = await _dio.get('${ApiConstants.DEPLOYMENTS}/$id');
    return DeploymentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CRÉATION
  // ─────────────────────────────────────────────────────────────────────────

  Future<DeploymentModel> createDeployment(Map<String, dynamic> body) async {
    debugPrint('=== POST /api/deployments ===');
    debugPrint('BODY: $body');
    try {
      final response = await _dio.post(ApiConstants.DEPLOYMENTS, data: body);
      return DeploymentModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException) {
        debugPrint('=== ERREUR CREATE 400 MESSAGE ===');
        debugPrint(e.response?.data.toString() ?? 'pas de message');
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MODIFICATION
  // ─────────────────────────────────────────────────────────────────────────

  Future<DeploymentModel> updateDeployment(
      int id, Map<String, dynamic> body) async {
    debugPrint('=== PUT /api/deployments/$id ===');
    debugPrint('BODY: $body');
    try {
      final response =
          await _dio.put('${ApiConstants.DEPLOYMENTS}/$id', data: body);
      return DeploymentModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      // ✅ Capture tout type d'exception
      debugPrint('=== ERREUR TYPE: ${e.runtimeType} ===');
      debugPrint('=== ERREUR MESSAGE: $e ===');
      try {
        // Tente d'extraire le response body quelle que soit l'exception
        final dynamic err = e;
        debugPrint('=== RESPONSE: ${err.response?.data} ===');
      } catch (_) {}
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SUPPRESSION
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> deleteDeployment(int id) async {
    await _dio.delete('${ApiConstants.DEPLOYMENTS}/$id');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ARCHIVAGE
  // ─────────────────────────────────────────────────────────────────────────

  Future<DeploymentModel> archiveDeployment(int id) async {
    final response = await _dio.put(
      '${ApiConstants.DEPLOYMENTS}/$id/archive',
      data: {'statut': DeploymentStatut.archive},
    );
    return DeploymentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CHANGEMENT DE STATUT
  // ─────────────────────────────────────────────────────────────────────────

  Future<DeploymentModel> updateStatut(int id, String statut) async {
    final response = await _dio.put(
      '${ApiConstants.DEPLOYMENTS}/$id/statut',
      data: {'statut': statut},
    );
    return DeploymentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CODE AUTO — génération locale uniquement
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> generateCode() async {
    return _generateCodeLocal();
  }

  String _generateCodeLocal() {
    final year = DateTime.now().year;
    final random = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000)
        .toString()
        .padLeft(4, '0');
    return 'DEP-$year-$random';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RÉFÉRENTIELS — pagination complète
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRegions() async {
    return _fetchAll(ApiConstants.REGIONS);
  }

  Future<List<Map<String, dynamic>>> getDistricts(int regionId) async {
    return _fetchAll(ApiConstants.DISTRICTS, params: {'regionId': regionId});
  }

  Future<List<Map<String, dynamic>>> getHealths(int districtId) async {
    return _fetchAll(ApiConstants.HEALTHS, params: {'districtId': districtId});
  }

  Future<List<Map<String, dynamic>>> getApps() async {
    return _fetchAll(ApiConstants.APPS);
  }

  Future<List<Map<String, dynamic>>> getPartners() async {
    return _fetchAll(ApiConstants.PARTNERS);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  _fetchAll — toutes les pages
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchAll(
    String route, {
    Map<String, dynamic>? params,
    int pageSize = 200,
  }) async {
    final all = <Map<String, dynamic>>[];
    int page = 0;
    int total = 0;

    do {
      final p = <String, dynamic>{
        'page': page,
        'size': pageSize,
        ...?params,
      };
      final response = await _dio.get(route, params: p);
      final data = response.data['data'];

      // Format 1 : liste directe
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }

      // Format 2 & 3 : page Spring Boot
      final content =
          (data['content'] as List? ?? []).cast<Map<String, dynamic>>();
      all.addAll(content);

      total = (data['page']?['totalElements'] as num?)?.toInt() ??
          (data['totalElements'] as num?)?.toInt() ??
          content.length;

      page++;
      if (content.isEmpty) break;
    } while (all.length < total);

    return all;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CHARGEMENT GROUPÉ (formulaire)
  // ─────────────────────────────────────────────────────────────────────────

  Future<DeploymentFormData> loadFormData() async {
    final results = await Future.wait([
      getRegions(),
      getApps(),
      getPartners(),
    ]);
    return DeploymentFormData(
      regions: results[0],
      apps: results[1],
      partners: results[2],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TOUS LES DÉPLOIEMENTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<DeploymentModel>> getAllDeployments({
    String? statut,
    int? regionId,
  }) async {
    final all = <DeploymentModel>[];
    int page = 0;
    int total = 0;

    do {
      final result = await getDeployments(
        page: page,
        size: 50,
        statut: statut,
        regionId: regionId,
      );
      all.addAll(result['items'] as List<DeploymentModel>);
      total = result['totalElements'] as int;
      page++;
    } while (all.length < total);

    return all;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DTO
// ─────────────────────────────────────────────────────────────────────────────

class DeploymentFormData {
  final List<Map<String, dynamic>> regions;
  final List<Map<String, dynamic>> apps;
  final List<Map<String, dynamic>> partners;

  const DeploymentFormData({
    required this.regions,
    required this.apps,
    required this.partners,
  });
}
