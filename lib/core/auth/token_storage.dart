// lib/core/auth/token_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  static const _keyToken = 'catusnis_token';
  static const _keyUser = 'catusnis_user';
  static const _keyEmail = 'catusnis_email';
  static const _keyPassword = 'catusnis_password';

  Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyToken);
  }

  Future<bool> hasToken() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_keyToken);
  }

  Future<void> saveUserData(String data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyUser, data);
  }

  Future<String?> getUserData() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyUser);
  }

  Future<void> saveCredentials(String email, String password) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyEmail, email);
    await p.setString(_keyPassword, password);
  }

  Future<String?> getSavedEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyEmail);
  }

  Future<String?> getSavedPassword() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyPassword);
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyToken);
    await p.remove(_keyUser);
  }

  Future<void> clearEverything() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
