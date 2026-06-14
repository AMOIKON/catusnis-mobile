// lib/features/fournitures/services/fourniture_service.dart

import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../models/fourniture_model.dart';

class FournitureService {
  static final FournitureService _i = FournitureService._();
  factory FournitureService() => _i;
  FournitureService._();

  final DioClient _dio = DioClient();

  int _total(dynamic d) =>
      (d?['totalElements'] as num?)?.toInt() ??
      (d?['page']?['totalElements'] as num?)?.toInt() ??
      0;
  int _pages(dynamic d) =>
      (d?['totalPages'] as num?)?.toInt() ??
      (d?['page']?['totalPages'] as num?)?.toInt() ??
      0;
  List _list(dynamic d) => (d?['content'] as List?) ?? [];

  // ── Articles ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFournitures({
    int page = 0,
    int size = 20,
    String? categorie,
    String? statut,
    String? keyword,
  }) async {
    final p = <String, dynamic>{'page': page, 'size': size};
    if (categorie != null) p['categorie'] = categorie;
    if (statut != null) p['statut'] = statut;
    if (keyword != null && keyword.isNotEmpty) p['keyword'] = keyword;

    final res = await _dio.get(ApiConstants.FOURNITURES, params: p);
    final data = res.data['data'] ?? res.data;
    return {
      'items': _list(data).map((e) => FournitureModel.fromJson(e)).toList(),
      'totalElements': _total(data),
      'totalPages': _pages(data),
    };
  }

  Future<FournitureModel> createFourniture(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConstants.FOURNITURES, data: body);
    return FournitureModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<FournitureModel> updateFourniture(
      int id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConstants.FOURNITURES}/$id', data: body);
    return FournitureModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<void> deleteFourniture(int id) async =>
      _dio.delete('${ApiConstants.FOURNITURES}/$id');

  // ── Déploiements ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDeploiements({
    int page = 0,
    int size = 20,
    int? fournitureId,
    bool? active,
    String? keyword,
  }) async {
    final p = <String, dynamic>{'page': page, 'size': size};
    if (fournitureId != null) p['fournitureId'] = fournitureId;
    if (active != null) p['active'] = active;
    if (keyword != null && keyword.isNotEmpty) p['keyword'] = keyword;

    final res =
        await _dio.get(ApiConstants.FOURNITURES_DEPLOIEMENTS, params: p);
    final data = res.data['data'] ?? res.data;
    return {
      'items': _list(data)
          .map((e) => FournitureDeploiementModel.fromJson(e))
          .toList(),
      'totalElements': _total(data),
      'totalPages': _pages(data),
    };
  }

  Future<FournitureDeploiementModel> createDeploiement(
      Map<String, dynamic> body) async {
    final res =
        await _dio.post(ApiConstants.FOURNITURES_DEPLOIEMENTS, data: body);
    return FournitureDeploiementModel.fromJson(res.data['data'] ?? res.data);
  }

  Future<void> cloturerDeploiement(int id) async =>
      _dio.put('${ApiConstants.FOURNITURES_DEPLOIEMENTS}/$id/cloturer');

  Future<void> deleteDeploiement(int id) async =>
      _dio.delete('${ApiConstants.FOURNITURES_DEPLOIEMENTS}/$id');

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<FournitureStats> getStats() async {
    try {
      final res = await _dio.get(ApiConstants.FOURNITURES_STATS);
      final data = res.data['data'] ?? res.data;
      return FournitureStats.fromJson(data);
    } catch (_) {
      return FournitureStats.empty();
    }
  }
}
