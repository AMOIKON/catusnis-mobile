// 📁 lib/core/services/server_wake_service.dart

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api_constants.dart';

enum WakeStatus { idle, waking, online, failed }

class ServerWakeService extends ChangeNotifier {
  static final ServerWakeService _instance = ServerWakeService._internal();
  factory ServerWakeService() => _instance;
  ServerWakeService._internal();

  WakeStatus _status = WakeStatus.idle;
  String _message = 'Connexion en cours…';
  int _attempt = 0;

  static const _maxAttempts = 4;

  WakeStatus get status => _status;
  String get message => _message;
  int get attempt => _attempt;
  bool get isWaking => _status == WakeStatus.waking;
  bool get isOnline => _status == WakeStatus.online;
  bool get hasFailed => _status == WakeStatus.failed;

  Future<bool> wakeUp() async {
    if (_status == WakeStatus.online) return true;

    _status = WakeStatus.waking;
    _attempt = 0;
    _message = 'Connexion au serveur…';
    notifyListeners();

    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.BASE_URL,
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 90),
    ));

    while (_attempt < _maxAttempts) {
      _attempt++;
      try {
        debugPrint('🔔 Wake-up tentative $_attempt/$_maxAttempts…');
        _message = _attempt == 1
            ? 'Connexion au serveur…'
            : 'Tentative $_attempt/$_maxAttempts…';
        notifyListeners();

        await dio.get(ApiConstants.HEALTH);

        _status = WakeStatus.online;
        _message = 'Serveur connecté ✓';
        notifyListeners();
        debugPrint('✅ Serveur réveillé (tentative $_attempt)');
        return true;
      } on DioException catch (e) {
        debugPrint('⚠️ Wake-up tentative $_attempt: ${e.type}');

        // Le serveur a répondu (même 401/403/404) → il tourne
        if (e.response != null) {
          _status = WakeStatus.online;
          _message = 'Serveur connecté ✓';
          notifyListeners();
          debugPrint('✅ Serveur joignable (${e.response!.statusCode})');
          return true;
        }

        // Timeout → serveur en train de se réveiller, réessayer
        if (_attempt < _maxAttempts) {
          _message = 'Démarrage du serveur… ($_attempt/$_maxAttempts)';
          notifyListeners();
          await Future.delayed(const Duration(seconds: 8));
        }
      } catch (e) {
        debugPrint('❌ Wake-up erreur: $e');
        if (_attempt < _maxAttempts) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }

    _status = WakeStatus.failed;
    _message = 'Serveur inaccessible. Vérifiez votre connexion.';
    notifyListeners();
    return false;
  }

  void reset() {
    _status = WakeStatus.idle;
    _attempt = 0;
    _message = 'Connexion en cours…';
    notifyListeners();
  }
}
