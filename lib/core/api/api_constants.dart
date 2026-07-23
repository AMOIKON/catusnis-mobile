// 📁 lib/core/api/api_constants.dart

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class ApiConstants {
  ApiConstants._();

  static const String _renderUrl = 'https://catsnis.onrender.com';

  // ── Backend local ─────────────────────────────────────────────────────────
  // Port 8082 en local (voir application.yml : server.port: 8082).
  // - Flutter Web (Chrome) : localhost fonctionne directement
  // - Émulateur Android : 10.0.2.2 pointe vers le localhost de la machine hôte
  // - Simulateur iOS : localhost fonctionne directement
  // - Appareil physique : remplacer par l'IP locale de la machine (ex: 192.168.x.x)
  static const String _localUrlWeb = 'http://localhost:8082';
  static const String _localUrlAndroidEmulator = 'http://10.0.2.2:8082';

  // ✅ Bascule manuelle : passer à false pour forcer Render même en debug
  static const bool _useLocalInDebug = true;

  static String get BASE_URL {
    if (kDebugMode && _useLocalInDebug) {
      // kIsWeb doit être vérifié en premier : un navigateur en debug
      // utilise localhost, pas 10.0.2.2 (qui n'a de sens que pour
      // l'émulateur Android natif).
      if (kIsWeb) return _localUrlWeb;
      return _localUrlAndroidEmulator;
    }
    return _renderUrl;
  }

  static String get displayUrl => BASE_URL;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String LOGIN = '/api/auth/login';
  static const String ME = '/api/auth/me';
  static const String LOGOUT = '/api/auth/logout';

  // ── Santé serveur (wake-up ping) ──────────────────────────────────────────
  static const String HEALTH = '/actuator/health';

  // ── Équipements ───────────────────────────────────────────────────────────
  static const String DEPLOYMENTS = '/api/deployments';
  static const String INTERVENTIONS = '/api/interventions';
  static const String ACQUISITIONS = '/api/acquisitions';
  static const String ARCHIVES = '/api/archives';
  static const String TYPES = '/api/types';

  // ── Logistique ────────────────────────────────────────────────────────────
  static const String VEHICULES = '/api/vehicules';
  static const String INCIDENTS = '/api/vehicules/incidents';
  static const String MAINTENANCES = '/api/vehicules/maintenances';
  static const String AFFECTATIONS = '/api/vehicules/affectations';
  static const String ALERTES_VEHICULES = '/api/vehicules/alertes';

  // ── Fournitures ───────────────────────────────────────────────────────────
  static const String FOURNITURES = '/api/fournitures';
  static const String FOURNITURES_DEPLOIEMENTS =
      '/api/fournitures/deploiements';
  static const String FOURNITURES_STATS = '/api/fournitures/stats';

  // ── Référentiels ──────────────────────────────────────────────────────────
  static const String HEALTHS = '/api/healths';
  static const String REGIONS = '/api/regions';
  static const String DISTRICTS = '/api/districts';
  static const String APPS = '/api/apps';
  static const String PARTNERS = '/api/partners';
  static const String PERSONS = '/api/persons';
  static const String BOOKLETS = '/api/booklets';
  static const String STRUCTURES_ETATIQUES = '/api/structures-etatiques';

  // ── Timeouts (Render free tier cold start ≈ 30-90s) ──────────────────────
  static const int connectTimeout = 180; // ✅ 3 min — couvre le cold start
  static const int receiveTimeout = 180; // ✅ 3 min

  // ── Headers ───────────────────────────────────────────────────────────────
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
