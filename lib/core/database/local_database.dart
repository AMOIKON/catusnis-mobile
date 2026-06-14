// lib/core/database/local_database.dart
//
// ✅ sqflite uniquement sur mobile/desktop (pas sur Web)
//    Sur Web : toutes les méthodes sont des no-ops silencieux

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  static Database? _db;

  // ── Accès DB — no-op sur Web ──────────────────────────────────────────────
  Future<Database?> get _database async {
    if (kIsWeb) return null; // sqflite non supporté sur web
    _db ??= await _initDb();
    return _db;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'catusnis_local.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        module        TEXT    NOT NULL,
        action        TEXT    NOT NULL,
        payload       TEXT    NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'pending',
        created_at    TEXT    NOT NULL,
        updated_at    TEXT,
        error_message TEXT,
        retry_count   INTEGER NOT NULL DEFAULT 0
      )
    ''');
    debugPrint('🗄️ LocalDatabase créée (v$version)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // migrations futures
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC QUEUE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> addToQueue({
    required String module,
    required String action,
    required String payload,
  }) async {
    final database = await _database;
    if (database == null) return; // web → skip silencieusement
    await database.insert('sync_queue', {
      'module': module,
      'action': action,
      'payload': payload,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
    debugPrint('💾 Queue ← $module/$action');
  }

  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final database = await _database;
    if (database == null) return [];
    return database.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<int> getPendingCount() async {
    final database = await _database;
    if (database == null) return 0;
    final result = await database.rawQuery(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE status = 'pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSynced(int id) async {
    final database = await _database;
    if (database == null) return;
    await database.update(
      'sync_queue',
      {
        'status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markError(int id, {String? message}) async {
    final database = await _database;
    if (database == null) return;
    await database.rawUpdate(
      '''UPDATE sync_queue
         SET status = 'error',
             retry_count = retry_count + 1,
             updated_at = ?,
             error_message = ?
         WHERE id = ?''',
      [DateTime.now().toIso8601String(), message, id],
    );
  }

  Future<void> clearSynced() async {
    final database = await _database;
    if (database == null) return;
    await database.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['synced'],
    );
  }
}
