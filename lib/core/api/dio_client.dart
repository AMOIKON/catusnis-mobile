// lib/core/api/dio_client.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'api_constants.dart';
import '../auth/token_storage.dart';

class DioClient {
  static DioClient? _instance;
  factory DioClient() {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  late final Dio _dio;
  final TokenStorage _storage = TokenStorage();

  DioClient._internal() {
    final baseUrl = ApiConstants.BASE_URL;
    debugPrint('🌐 DioClient init — BaseURL: $baseUrl');

    // Headers de base — ngrok-skip-browser-warning retiré (bloqué par CORS en web)
    final Map<String, dynamic> baseHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConstants.receiveTimeout),
      headers: baseHeaders,
    ));

    // Fix SSL Android
    if (!kIsWeb) {
      try {
        (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
          final client = HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
          return client;
        };
      } catch (e) {
        debugPrint('SSL bypass error: $e');
      }
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!kIsWeb) {
          options.headers['User-Agent'] = 'CATUSNIS-Mobile/1.0.0';
        }
        final token = await _storage.getToken();
        if (token != null) {
          options.headers[ApiConstants.authHeader] =
              '${ApiConstants.bearerPrefix}$token';
        }
        debugPrint('→ ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('← ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (DioException error, handler) async {
        debugPrint('✗ ${error.type} ${error.message}');
        if (error.response?.statusCode == 401) {
          await _storage.clearAll();
        }
        handler.next(error);
      },
    ));
  }

  // ── Méthodes HTTP ─────────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? params,
  }) async =>
      _run(() => _dio.get(path, queryParameters: params));

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async =>
      _run(() => _dio.post(path, data: data, queryParameters: params));

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async =>
      _run(() => _dio.put(path, data: data, queryParameters: params));

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? params,
  }) async =>
      _run(() => _dio.delete(path, queryParameters: params));

  Future<Response> postFormData(
    String path, {
    required FormData data,
  }) async =>
      _run(() => _dio.post(
            path,
            data: data,
            options: Options(contentType: 'multipart/form-data'),
          ));

  // ── Gestion erreurs ───────────────────────────────────────────────────────

  Future<Response> _run(Future<Response> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai dépassé. Vérifiez votre réseau.');
      case DioExceptionType.connectionError:
        return Exception(
            'Impossible de joindre le serveur.\nVérifiez votre connexion internet.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = e.response?.data?['message'] ?? 'Erreur serveur';
        return Exception('[$code] $msg');
      default:
        return Exception(e.message ?? 'Erreur réseau inconnue');
    }
  }
}
