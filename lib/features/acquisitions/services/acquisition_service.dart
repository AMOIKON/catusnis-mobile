// lib/features/acquisitions/services/acquisition_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/acquisition_model.dart';

class AcquisitionService {
  static final AcquisitionService _instance = AcquisitionService._internal();
  factory AcquisitionService() => _instance;
  AcquisitionService._internal();

  final DioClient _dio = DioClient();

  Future<Map<String, dynamic>> getAcquisitions({
    int page = 0,
    int size = 50,
    int? typesId,
    String? keyword,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': 'id,desc',
    };
    if (typesId != null) params['typesId'] = typesId;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await _dio.get(ApiConstants.ACQUISITIONS, params: params);
    final data = response.data['data'];
    final total = (data['page']['totalElements'] as num?)?.toInt() ?? 0;
    final pages = (data['page']['totalPages'] as num?)?.toInt() ?? 0;
    final items = (data['content'] as List)
        .map((e) => AcquisitionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'items': items,
      'totalElements': total,
      'totalPages': pages,
    };
  }

  Future<void> deleteAcquisition(int id) async {
    await _dio.delete('${ApiConstants.ACQUISITIONS}/$id');
  }
}
