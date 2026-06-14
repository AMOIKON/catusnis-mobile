// lib/features/persons/services/person_service.dart

import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/person.dart';

class PersonService {
  final DioClient _client = DioClient();

  /// Récupérer toutes les personnes
  Future<List<Person>> getAllList() async {
    final response = await _client.get(ApiConstants.PERSONS);
    return _parseList(response.data);
  }

  /// Techniciens + logisticiens uniquement (filtrage côté client)
  Future<List<Person>> getAssignables() async {
    final all = await getAllList();
    return all.where((p) {
      final r = p.role?.toUpperCase();
      return r == 'TECHNICIEN' || r == 'LOGISTICIEN';
    }).toList();
  }

  /// Récupérer une personne par ID
  Future<Person> getById(int id) async {
    final response = await _client.get('${ApiConstants.PERSONS}/$id');
    final raw = response.data;
    final map = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return Person.fromJson(map);
  }

  // ── Helper parsing robuste ────────────────────────────────────────────────
  List<Person> _parseList(dynamic raw) {
    List<dynamic> list = [];

    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        final content = data['content'];
        if (content is List) list = content;
      }
    }

    return list.whereType<Map<String, dynamic>>().map(Person.fromJson).toList();
  }
}
