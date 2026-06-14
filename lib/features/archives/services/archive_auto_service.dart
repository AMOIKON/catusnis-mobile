// lib/features/archives/services/archive_auto_service.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';

class ArchiveAutoService {
  final DioClient _client = DioClient();

  static const String _endpoint = '/api/archives/auto';

  // ── Archiver un déploiement ───────────────────────────────────────────────
  Future<Map<String, dynamic>> archiveDeployment({
    required Map<String, dynamic> deployment,
    required Uint8List pdfBytes,
    required bool withSignature,
    required String archivedBy,
  }) async {
    final code = deployment['codeDep']?.toString() ?? 'DEP';
    final titre = withSignature
        ? 'Fiche déploiement $code (signée)'
        : 'Fiche déploiement $code';

    return _upload(
      pdfBytes: pdfBytes,
      titre: titre,
      categorie: 'DEPLOIEMENT',
      relatedCode: code,
      description: _deploymentDesc(deployment),
      archivedBy: archivedBy,
      withSignature: withSignature,
    );
  }

  // ── Archiver une intervention ─────────────────────────────────────────────
  Future<Map<String, dynamic>> archiveIntervention({
    required Map<String, dynamic> intervention,
    required Uint8List pdfBytes,
    required bool withSignature,
    required String archivedBy,
  }) async {
    final code = intervention['codeInter']?.toString() ?? 'INT';
    final type = intervention['typeInter']?.toString() ?? '';
    final titre = withSignature
        ? 'Rapport intervention $code ($type - signé)'
        : 'Rapport intervention $code ($type)';

    return _upload(
      pdfBytes: pdfBytes,
      titre: titre,
      categorie: 'INTERVENTION',
      relatedCode: code,
      description: _interventionDesc(intervention),
      archivedBy: archivedBy,
      withSignature: withSignature,
    );
  }

  // ── Upload multipart ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _upload({
    required Uint8List pdfBytes,
    required String titre,
    required String categorie,
    required String relatedCode,
    required String description,
    required String archivedBy,
    required bool withSignature,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        pdfBytes,
        filename: '${categorie.toLowerCase()}_$relatedCode.pdf',
        contentType: DioMediaType('application', 'pdf'),
      ),
      'titre': titre,
      'categorie': categorie,
      'relatedCode': relatedCode,
      'description': description,
      'archivedBy': archivedBy,
      'withSignature': withSignature.toString(),
    });

    final response = await _client.postFormData(_endpoint, data: formData);
    final raw = response.data;
    if (raw is Map && raw['data'] != null) {
      return (raw['data'] as Map).cast<String, dynamic>();
    }
    if (raw is Map) return raw.cast<String, dynamic>();
    return {};
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _deploymentDesc(Map<String, dynamic> dep) {
    return [
      if (dep['regionName'] != null) 'Région : ${dep['regionName']}',
      if (dep['districtName'] != null) 'District : ${dep['districtName']}',
      if (dep['healthName'] != null) 'Site : ${dep['healthName']}',
      if (dep['statut'] != null) 'Statut : ${dep['statut']}',
    ].join(' | ');
  }

  String _interventionDesc(Map<String, dynamic> inter) {
    return [
      if (inter['typeInter'] != null) 'Type : ${inter['typeInter']}',
      if (inter['actionInter'] != null) 'Action : ${inter['actionInter']}',
      if (inter['healthName'] != null) 'Site : ${inter['healthName']}',
      if (inter['technicianName'] != null)
        'Technicien : ${inter['technicianName']}',
    ].join(' | ');
  }
}
