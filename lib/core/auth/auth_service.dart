// lib/core/auth/auth_service.dart

import 'package:flutter/foundation.dart' show debugPrint;
import '../api/dio_client.dart';
import '../api/api_constants.dart';
import '../models/user_model.dart';
import 'token_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DioClient _dio = DioClient();
  final TokenStorage _storage = TokenStorage();

  // ── Login en ligne ────────────────────────────────────────────────
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.LOGIN,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);

      await _storage.saveToken(auth.token);
      await _storage.saveUserData(auth.user.toJsonString());
      await _storage.saveCredentials(email.trim().toLowerCase(), password);

      return auth;
    } catch (e) {
      throw Exception(_parseError(e.toString()));
    }
  }

  // ── Login hors ligne ──────────────────────────────────────────────
  Future<AuthResponse?> loginOffline({
    required String email,
    required String password,
  }) async {
    try {
      final savedEmail = await _storage.getSavedEmail();
      final savedPassword = await _storage.getSavedPassword();
      final token = await _storage.getToken();
      final userData = await _storage.getUserData();

      if (savedEmail == null) return null;
      if (savedPassword == null) return null;
      if (token == null) return null;
      if (userData == null) return null;

      if (savedEmail != email.trim().toLowerCase()) return null;
      if (savedPassword != password) return null;

      final user = UserModel.fromJsonString(userData);
      return AuthResponse(token: token, user: user);
    } catch (_) {
      return null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async => _storage.clearAll();

  // ── Connecté ? ────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    if (!await _storage.hasToken()) return false;
    final token = await _storage.getToken();
    if (token == null) return false;
    // ✅ Ne pas vérifier l'expiration côté client
    // Le serveur retournera 401 si le token est expiré
    return true;
  }

  // ── Utilisateur courant ───────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    try {
      final json = await _storage.getUserData();
      if (json == null) return null;
      return UserModel.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  // ── A des credentials offline ? ───────────────────────────────────
  Future<bool> hasOfflineCredentials() async {
    final email = await _storage.getSavedEmail();
    final pass = await _storage.getSavedPassword();
    return email != null && pass != null;
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String _parseError(String error) {
    debugPrint('Auth error: $error');
    if (error.contains('401') || error.contains('incorrect'))
      return 'Email ou mot de passe incorrect';
    if (error.contains('connection') ||
        error.contains('joindre') ||
        error.contains('timeout') ||
        error.contains('SocketException')) return 'Pas de connexion réseau';
    return error.replaceAll('Exception: ', '');
  }
}
