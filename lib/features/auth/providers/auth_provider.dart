// lib/features/auth/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/models/user_model.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  UserModel? _user;
  String? _error;
  bool _loading = false;
  bool _isOfflineSession = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _loading;
  bool get isAuth => _status == AuthStatus.authenticated;
  bool get isChecking => _status == AuthStatus.checking;
  bool get isOfflineSession => _isOfflineSession;

  final AuthService _authService = AuthService();

  // ── Initialisation au démarrage ───────────────────────────────────
  Future<void> initialize() async {
    _setStatus(AuthStatus.checking);
    try {
      if (await _authService.isLoggedIn()) {
        _user = await _authService.getCurrentUser();
        _isOfflineSession = false;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────
  // ✅ Essaie TOUJOURS en ligne d'abord
  // Si erreur réseau → bascule offline automatiquement
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // ✅ Tentative en ligne TOUJOURS en premier
      final auth = await _authService.login(email: email, password: password);
      _user = auth.user;
      _isOfflineSession = false;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      debugPrint('Login error: $msg');

      // ✅ Si erreur réseau → tenter offline
      if (_isNetworkError(msg)) {
        return await _tryOfflineLogin(email, password);
      }

      // Erreur credentials incorrects → afficher le message
      _error = msg;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool _isNetworkError(String msg) {
    return msg.contains('réseau') ||
        msg.contains('connexion') ||
        msg.contains('timeout') ||
        msg.contains('joindre') ||
        msg.contains('Délai') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host') ||
        msg.contains('network');
  }

  Future<bool> _tryOfflineLogin(String email, String password) async {
    final auth =
        await _authService.loginOffline(email: email, password: password);

    if (auth != null) {
      _user = auth.user;
      _isOfflineSession = true;
      _setStatus(AuthStatus.authenticated);
      return true;
    }

    _error = 'Impossible de joindre le serveur.\n'
        'Vérifiez votre connexion internet.';
    notifyListeners();
    return false;
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _error = null;
    _isOfflineSession = false;
    _setStatus(AuthStatus.unauthenticated);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
