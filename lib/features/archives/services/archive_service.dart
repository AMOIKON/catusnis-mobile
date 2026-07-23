// lib/features/archives/services/archive_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/api/dio_client.dart';
import '../models/archive_model.dart';

class ArchiveService {
  static final ArchiveService _instance = ArchiveService._internal();
  factory ArchiveService() => _instance;
  ArchiveService._internal();

  final DioClient _dio = DioClient();
  static const String _endpoint = '/api/archives';

  // ── Liste paginée ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getArchives({
    int page = 0,
    int size = 10,
    String? type,
    String? categorie,
    String? keyword,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (type != null) params['type'] = type;
    if (categorie != null) params['categorie'] = categorie;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await _dio.get(_endpoint, params: params);
    final data = response.data as Map<String, dynamic>;
    final total = (data['page']['totalElements'] as num?)?.toInt() ?? 0;
    final pages = (data['page']['totalPages'] as num?)?.toInt() ?? 0;
    final items = <ArchiveModel>[];
    for (final e in (data['content'] as List)) {
      items.add(ArchiveModel.fromJson(e as Map<String, dynamic>));
    }
    return {'items': items, 'totalElements': total, 'totalPages': pages};
  }

  // ── Créer archive imprimée (sans fichier) ──────────────────────────────────
  Future<Map<String, dynamic>> createArchiveImprime(
      Map<String, dynamic> body) async {
    final response = await _dio.post('$_endpoint/imprime', data: body);
    return response.data as Map<String, dynamic>;
  }

  // ── Créer archive scannée — mobile (File) ──────────────────────────────────
  Future<Map<String, dynamic>> createArchiveScanne({
    File? file,
    Uint8List? bytes,
    required String fileName,
    required String titre,
    required String categorie,
    String? description,
    String? relatedCode,
  }) async {
    final mimeType = _getMimeType(fileName);

    final dataJson = _toJsonString({
      'titre': titre,
      'type': 'SCANNE',
      'categorie': categorie,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (relatedCode != null && relatedCode.isNotEmpty)
        'relatedCode': relatedCode,
    });

    MultipartFile fileMultipart;

    if (kIsWeb && bytes != null) {
      // Web : utiliser les bytes directement
      fileMultipart = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      );
    } else if (file != null) {
      // Mobile : utiliser le path
      fileMultipart = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      );
    } else {
      throw Exception('Aucun fichier fourni');
    }

    final formData = FormData.fromMap({
      'file': fileMultipart,
      'data': MultipartFile.fromString(
        dataJson,
        contentType: DioMediaType.parse('application/json'),
      ),
    });

    final response = await _dio.postFormData(
      '$_endpoint/upload',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Mettre à jour ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateArchive(
      int id, Map<String, dynamic> body) async {
    final response = await _dio.put('$_endpoint/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  // ── Supprimer ──────────────────────────────────────────────────────────────
  Future<void> deleteArchive(int id) async {
    await _dio.delete('$_endpoint/$id');
  }

  // ── Télécharger le fichier BLOB d'une archive ──────────────────────────────
  //  Confirmé via ArchiveController.java : GET /api/archives/download/{id}
  Future<Uint8List> downloadArchiveFile(int id) async {
    final response = await _dio.getBytes('$_endpoint/download/$id');
    return Uint8List.fromList(response.data ?? []);
  }

  // ── Stats (compteurs par catégorie/type) ───────────────────────────────────
  Future<Map<String, int>> getStats() async {
    final response = await _dio.get('$_endpoint/stats');
    final data = response.data as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  String _toJsonString(Map<String, dynamic> map) {
    final entries = map.entries.map((e) {
      final val = e.value is String ? '"${e.value}"' : '${e.value}';
      return '"${e.key}":$val';
    }).join(',');
    return '{$entries}';
  }
}
