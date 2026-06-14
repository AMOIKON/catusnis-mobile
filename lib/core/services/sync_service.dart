// lib/core/services/sync_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/dio_client.dart';
import '../api/api_constants.dart';
import '../database/local_database.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DioClient _dio = DioClient();
  final LocalDatabase _localDb = LocalDatabase();
  final ConnectivityService _conn = ConnectivityService();

  bool _isSyncing = false;
  int _pending = 0;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pending;

  // ── Déclencher sync quand réseau revient ──────────────────────────
  void listenConnectivity() {
    _conn.addListener(() {
      if (_conn.isOnline) {
        debugPrint('🔄 Réseau revenu — sync en cours...');
        syncAll();
      }
    });
  }

  // ── Synchroniser tout ─────────────────────────────────────────────
  Future<void> syncAll() async {
    if (_isSyncing || _conn.isOffline) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final queue = await _localDb.getPendingQueue();
      debugPrint('📤 ${queue.length} élément(s) à synchroniser');

      for (final item in queue) {
        await _syncItem(item);
      }

      _pending = await _localDb.getPendingCount();
    } catch (e) {
      debugPrint('❌ Erreur sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ── Synchroniser un élément ───────────────────────────────────────
  Future<void> _syncItem(Map<String, dynamic> item) async {
    try {
      final payload = jsonDecode(item['payload'] as String);
      final module = item['module'] as String;
      final action = item['action'] as String;

      String endpoint;
      switch (module) {
        case 'acquisitions':
          endpoint = ApiConstants.ACQUISITIONS;
          break;
        case 'interventions':
          endpoint = ApiConstants.INTERVENTIONS;
          break;
        case 'deployments':
          endpoint = ApiConstants.DEPLOYMENTS;
          break;
        default:
          return;
      }

      if (action == 'create') {
        await _dio.post(endpoint, data: payload);
        await _localDb.markSynced(item['id'] as int);
        debugPrint('✅ Synchronisé: $module #${item['id']}');
      }
    } catch (e) {
      await _localDb.markError(item['id'] as int);
      debugPrint('❌ Erreur sync item ${item['id']}: $e');
    }
  }

  // ── Sauvegarder en local + file d'attente ─────────────────────────
  Future<void> saveOffline({
    required String module,
    required Map<String, dynamic> data,
  }) async {
    await _localDb.addToQueue(
      module: module,
      action: 'create',
      payload: jsonEncode(data),
    );
    _pending = await _localDb.getPendingCount();
    notifyListeners();
    debugPrint('💾 Sauvegardé hors ligne: $module');
  }

  // ── Mettre à jour le compteur ─────────────────────────────────────
  Future<void> refreshPendingCount() async {
    _pending = await _localDb.getPendingCount();
    notifyListeners();
  }
}
