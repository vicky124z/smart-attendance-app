import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin HTTP wrapper around the Django REST backend.
///
/// - Attaches the `Authorization: Bearer <access>` header automatically.
/// - Transparently retries a request once after refreshing the access
///   token if the server responds with 401.
/// - Converts non-2xx responses into [ApiException].
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  final _storage = TokenStorage.instance;

  /// Called when the refresh token itself is rejected (session fully
  /// expired) so the app can route the user back to login.
  void Function()? onSessionExpired;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.baseUrl;
    final full = path.startsWith('http') ? path : '$base$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) {
    return _send('PUT', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _send('DELETE', path, auth: auth);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(auth: auth);
    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.requestTimeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.requestTimeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(ApiConfig.requestTimeout);
          break;
        default:
          throw ApiException('Unsupported method $method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }

    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return _send(method, path, body: body, query: query, auth: auth, isRetry: true);
      }
      onSessionExpired?.call();
      throw ApiException('Your session has expired. Please log in again.', statusCode: 401);
    }

    return _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    final status = response.statusCode;
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    throw ApiException.fromBody(decoded, statusCode: status);
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null) return false;
    try {
      final uri = _uri('/accounts/auth/refresh/');
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': refresh}))
          .timeout(ApiConfig.requestTimeout);
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccess = data['access'] as String?;
      if (newAccess == null) return false;
      await _storage.saveAccessToken(newAccess);
      return true;
    } catch (_) {
      return false;
    }
  }
}
