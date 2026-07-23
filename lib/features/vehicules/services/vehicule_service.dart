// lib/features/vehicules/services/vehicule_service.dart

import 'dart:typed_data';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../models/vehicule_model.dart';

class VehiculeService {
  static final VehiculeService _i = VehiculeService._();
  factory VehiculeService() => _i;
  VehiculeService._();

  final DioClient _dio = DioClient();

  // ── Helpers ────────────────────────────────────────────────────────────────
  int _total(dynamic data) =>
      (data?['page']?['totalElements'] as num?)?.toInt() ?? 0;
  int _pages(dynamic data) =>
      (data?['page']?['totalPages'] as num?)?.toInt() ?? 0;
  List _list(dynamic data) => (data?['content'] as List?) ?? [];

  // ── Véhicules ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVehicules({
    int page = 0,
    int size = 20,
    String? type,
    String? statut,
    String? keyword,
  }) async {
    final p = <String, dynamic>{'page': page, 'size': size};
    if (type != null) p['type'] = type;
    if (statut != null) p['statut'] = statut;
    if (keyword != null && keyword.isNotEmpty) p['keyword'] = keyword;

    final res = await _dio.get(ApiConstants.VEHICULES, params: p);
    final data = res.data['data'];
    return {
      'items': _list(data).map((e) => VehiculeModel.fromJson(e)).toList(),
      'totalElements': _total(data),
      'totalPages': _pages(data),
    };
  }

  Future<VehiculeModel> getVehicule(int id) async {
    final res = await _dio.get('${ApiConstants.VEHICULES}/$id');
    return VehiculeModel.fromJson(res.data['data']);
  }

  Future<VehiculeModel> createVehicule(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.VEHICULES, data: body);
    return VehiculeModel.fromJson(res.data['data']);
  }

  Future<VehiculeModel> updateVehicule(
      int id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.VEHICULES}/$id', data: body);
    return VehiculeModel.fromJson(res.data['data']);
  }

  Future<void> deleteVehicule(int id) async =>
      _dio.delete('${ApiConstants.VEHICULES}/$id');

  // ── NOUVEAU — Fiche PDF (téléchargement des bytes) ──────────────────────────
  //  Appelle GET /api/vehicules/{id}/pdf — déclenche aussi l'archivage
  //  automatique BLOB côté backend (voir VehiculeServiceImpl.generateVehiculePdf).
  Future<Uint8List> downloadVehiculePdf(int id) async {
    final response = await _dio.getBytes('${ApiConstants.VEHICULES}/$id/pdf');
    return Uint8List.fromList(response.data ?? []);
  }

  // ── Incidents ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getIncidents({
    int page = 0,
    int size = 20,
    int? vehiculeId,
    String? statut,
  }) async {
    final p = <String, dynamic>{'page': page, 'size': size};
    if (vehiculeId != null) p['vehiculeId'] = vehiculeId;
    if (statut != null) p['statut'] = statut;

    final res = await _dio.get(ApiConstants.INCIDENTS, params: p);
    final data = res.data['data'];
    return {
      'items':
          _list(data).map((e) => VehiculeIncidentModel.fromJson(e)).toList(),
      'totalElements': _total(data),
      'totalPages': _pages(data),
    };
  }

  Future<VehiculeIncidentModel> createIncident(
      Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.INCIDENTS, data: body);
    return VehiculeIncidentModel.fromJson(res.data['data']);
  }

  Future<VehiculeIncidentModel> updateIncident(
      int id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.INCIDENTS}/$id', data: body);
    return VehiculeIncidentModel.fromJson(res.data['data']);
  }

  Future<void> deleteIncident(int id) async =>
      _dio.delete('${ApiConstants.INCIDENTS}/$id');

  // ── Maintenances ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMaintenances({
    int page = 0,
    int size = 20,
    int? vehiculeId,
    String? statut,
  }) async {
    final p = <String, dynamic>{'page': page, 'size': size};
    if (vehiculeId != null) p['vehiculeId'] = vehiculeId;
    if (statut != null) p['statut'] = statut;

    final res = await _dio.get(ApiConstants.MAINTENANCES, params: p);
    final data = res.data['data'];
    return {
      'items':
          _list(data).map((e) => VehiculeMaintenanceModel.fromJson(e)).toList(),
      'totalElements': _total(data),
      'totalPages': _pages(data),
    };
  }

  Future<VehiculeMaintenanceModel> createMaintenance(
      Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.MAINTENANCES, data: body);
    return VehiculeMaintenanceModel.fromJson(res.data['data']);
  }

  Future<VehiculeMaintenanceModel> updateMaintenance(
      int id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.MAINTENANCES}/$id', data: body);
    return VehiculeMaintenanceModel.fromJson(res.data['data']);
  }

  Future<void> deleteMaintenance(int id) async =>
      _dio.delete('${ApiConstants.MAINTENANCES}/$id');

  // ── Affectations ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAffectations({
    int page = 0,
    int size = 20,
    int? vehiculeId,
    bool? active,
  }) async {
    final p = <String, dynamic>{'page': page, 'size': size};
    if (vehiculeId != null) p['vehiculeId'] = vehiculeId;
    if (active != null) p['active'] = active;

    final res = await _dio.get(ApiConstants.AFFECTATIONS, params: p);
    final data = res.data['data'];
    return {
      'items':
          _list(data).map((e) => VehiculeAffectationModel.fromJson(e)).toList(),
      'totalElements': _total(data),
      'totalPages': _pages(data),
    };
  }

  Future<VehiculeAffectationModel> createAffectation(
      Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.AFFECTATIONS, data: body);
    return VehiculeAffectationModel.fromJson(res.data['data']);
  }

  Future<void> cloturerAffectation(int vehiculeId) async =>
      _dio.put('${ApiConstants.VEHICULES}/$vehiculeId/cloturer-affectation');

  // ── Alertes ───────────────────────────────────────────────────────────────

  Future<List<VehiculeAlerteModel>> getAlertes({int joursAvance = 30}) async {
    final res = await _dio.get(ApiConstants.ALERTES_VEHICULES,
        params: {'joursAvance': joursAvance});
    final data = res.data['data'];
    if (data is List) {
      return data.map((e) => VehiculeAlerteModel.fromJson(e)).toList();
    }
    return [];
  }
}
