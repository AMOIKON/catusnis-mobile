// lib/features/acquisitions/services/acquisition_form_service.dart

import 'dart:convert';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';

class AcquisitionFormService {
  AcquisitionFormService();

  final DioClient _dio = DioClient();

  static String _fixEncoding(String s) {
    if (s.isEmpty) return s;
    try {
      return utf8.decode(latin1.encode(s));
    } catch (_) {
      return s;
    }
  }

  Future<List<Map<String, dynamic>>> getTypes() async {
    final response =
        await _dio.get('/api/types', params: {'page': 0, 'size': 100});
    final raw = List<Map<String, dynamic>>.from(
        response.data['data']['content'] as List);
    return raw.map((t) {
      final rawName = t['type'] as String? ??
          t['typeName'] as String? ??
          t['name'] as String? ??
          '';
      return {
        'id': t['id'],
        'typeName': _fixEncoding(rawName),
        'marque':
            _fixEncoding(t['marque'] as String? ?? t['brand'] as String? ?? ''),
        'modele':
            _fixEncoding(t['modele'] as String? ?? t['model'] as String? ?? ''),
        'image': t['image'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPartners() async {
    final response =
        await _dio.get('/api/partners', params: {'page': 0, 'size': 50});
    final raw = response.data['data'];
    final list = raw is List
        ? List<Map<String, dynamic>>.from(raw)
        : List<Map<String, dynamic>>.from(raw['content'] as List);
    return list.map((p) {
      final rawName = p['partnerName'] as String? ??
          p['name'] as String? ??
          p['nomPartenaire'] as String? ??
          '';
      return {
        'id': p['id'],
        'partnerName': _fixEncoding(rawName),
        'image': p['image'] ?? p['logo'] ?? '',
      };
    }).toList();
  }

  Future<Map<String, dynamic>> createAcquisition(
      Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.ACQUISITIONS, data: body);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAcquisition(
      int id, Map<String, dynamic> body) async {
    final response =
        await _dio.put('${ApiConstants.ACQUISITIONS}/$id', data: body);
    return response.data['data'] as Map<String, dynamic>;
  }
}
