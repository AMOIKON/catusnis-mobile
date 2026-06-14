// lib/core/services/cache_service.dart
//
// ✅ Cross-platform : shared_preferences (web + mobile + desktop)
//    sqflite n'est pas supporté sur Flutter Web

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final ConnectivityService _conn = ConnectivityService();

  bool get isOffline => _conn.isOffline;

  // ── Clés de cache standardisées ──────────────────────────────────────────
  static const kAcquisitions = 'acquisitions_list';
  static const kDeployments = 'deployments_list';
  static const kInterventions = 'interventions_list';
  static const kBooklets = 'booklets_list';
  static const kVehicules = 'vehicules_list';
  static const kFournitures = 'fournitures_list';
  static const kArchives = 'archives_list';
  static const kBookletStatuses = 'booklet_statuses_list';
  static const kTechnicianSites = 'technician_sites_list';
  static const kDashboardStats = 'dashboard_stats';

  // ── Clés internes shared_preferences ─────────────────────────────────────
  static String _dataKey(String key) => 'cache_data_$key';
  static String _cachedAtKey(String key) => 'cache_at_$key';
  static String _expiresAtKey(String key) => 'cache_exp_$key';

  // ── Écriture ──────────────────────────────────────────────────────────────

  Future<void> saveList({
    required String key,
    required List<dynamic> items,
    Duration ttl = const Duration(hours: 24),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_dataKey(key), jsonEncode(items));
      await prefs.setString(_cachedAtKey(key), now.toIso8601String());
      await prefs.setString(_expiresAtKey(key), now.add(ttl).toIso8601String());
      debugPrint('💾 Cache ← $key (${items.length} items)');
    } catch (e) {
      debugPrint('⚠️ Cache write $key: $e');
    }
  }

  Future<void> saveObject({
    required String key,
    required Map<String, dynamic> data,
    Duration ttl = const Duration(hours: 1),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_dataKey(key), jsonEncode(data));
      await prefs.setString(_cachedAtKey(key), now.toIso8601String());
      await prefs.setString(_expiresAtKey(key), now.add(ttl).toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Cache write $key: $e');
    }
  }

  // ── Lecture ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> getList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier expiration
      final expStr = prefs.getString(_expiresAtKey(key));
      if (expStr != null && DateTime.now().isAfter(DateTime.parse(expStr))) {
        await invalidate(key);
        return null;
      }

      final raw = prefs.getString(_dataKey(key));
      if (raw == null) return null;
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('⚠️ Cache read $key: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expStr = prefs.getString(_expiresAtKey(key));
      if (expStr != null && DateTime.now().isAfter(DateTime.parse(expStr))) {
        await invalidate(key);
        return null;
      }
      final raw = prefs.getString(_dataKey(key));
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasCache(String key) async {
    final list = await getList(key);
    return list != null;
  }

  Future<DateTime?> getCachedAt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cachedAtKey(key));
      return str != null ? DateTime.tryParse(str) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Invalidation ──────────────────────────────────────────────────────────

  Future<void> invalidate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey(key));
    await prefs.remove(_cachedAtKey(key));
    await prefs.remove(_expiresAtKey(key));
    debugPrint('🗑️ Cache invalidé: $key');
  }

  Future<void> invalidateAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('🗑️ Cache entièrement vidé (${keys.length} entrées)');
  }

  Future<void> invalidateModule(String module) async {
    final keyMap = {
      'acquisitions': kAcquisitions,
      'deployments': kDeployments,
      'interventions': kInterventions,
      'booklets': kBooklets,
      'vehicules': kVehicules,
      'fournitures': kFournitures,
      'archives': kArchives,
    };
    final key = keyMap[module];
    if (key != null) await invalidate(key);
  }

  // ── Chargement réseau + cache ─────────────────────────────────────────────

  Future<
      ({
        List<Map<String, dynamic>> items,
        bool fromCache,
        DateTime? cachedAt
      })> loadList({
    required String cacheKey,
    required Future<List<dynamic>> Function() fetchFromNetwork,
    Duration ttl = const Duration(hours: 24),
  }) async {
    if (_conn.isOnline) {
      try {
        final raw = await fetchFromNetwork();
        final items = raw.whereType<Map<String, dynamic>>().toList();
        await saveList(key: cacheKey, items: items, ttl: ttl);
        return (items: items, fromCache: false, cachedAt: null);
      } catch (e) {
        debugPrint('⚠️ Réseau KO → cache pour $cacheKey : $e');
      }
    }

    final cached = await getList(cacheKey);
    final cachedAt = await getCachedAt(cacheKey);
    if (cached != null) {
      debugPrint('📦 Cache → $cacheKey (${cached.length} items)');
      return (items: cached, fromCache: true, cachedAt: cachedAt);
    }

    return (items: <Map<String, dynamic>>[], fromCache: false, cachedAt: null);
  }
}
