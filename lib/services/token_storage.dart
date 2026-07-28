import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] so access/refresh JWTs never touch
/// plain-text shared preferences.
class TokenStorage {
  TokenStorage._internal();
  static final TokenStorage instance = TokenStorage._internal();

  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'sa_access_token';
  static const _refreshKey = 'sa_refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccessToken(String access) async {
    await _storage.write(key: _accessKey, value: access);
  }

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
