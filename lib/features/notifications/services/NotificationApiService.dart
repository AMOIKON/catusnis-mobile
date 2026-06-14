// lib/features/notifications/services/notification_api_service.dart

import '../../../core/api/dio_client.dart';
import '../../notifications/models/NotificationModel.dart';

class NotificationApiService {
  final DioClient _client = DioClient();

  static const String _base = '/api/notifications';

  // ── Polling : nouvelles depuis un timestamp ───────────────────────────────
  Future<List<NotificationModel>> getSince({
    required int userId,
    required DateTime since,
  }) async {
    try {
      final response = await _client.get(
        '$_base/since',
        params: {
          'userId': userId,
          'timestamp': since.toIso8601String(),
        },
      );
      final raw = response.data;
      List<dynamic> list = raw is List ? raw : (raw['content'] ?? []);
      return list
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Compteur non lus ─────────────────────────────────────────────────────
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _client.get(
        '$_base/unread-count',
        params: {'userId': userId},
      );
      return (response.data['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Liste paginée ─────────────────────────────────────────────────────────
  Future<List<NotificationModel>> getAll({
    required int userId,
    int page = 0,
    int size = 30,
  }) async {
    try {
      final response = await _client.get(
        _base,
        params: {'userId': userId, 'page': page, 'size': size},
      );
      final raw = response.data;
      final content =
          raw is Map ? (raw['content'] as List? ?? []) : (raw as List);
      return content
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Marquer comme lu ─────────────────────────────────────────────────────
  Future<void> markRead(int notifId) async {
    try {
      await _client.put('$_base/$notifId/read');
    } catch (_) {}
  }

  // ── Tout marquer comme lu ────────────────────────────────────────────────
  Future<void> markAllRead(int userId) async {
    try {
      await _client.put(
        '$_base/read-all',
        params: {'userId': userId},
      );
    } catch (_) {}
  }
}
