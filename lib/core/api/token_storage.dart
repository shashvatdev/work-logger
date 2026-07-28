import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles storing, reading and clearing JWT tokens securely.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyThemeMode = 'theme_mode';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccess, value: accessToken),
      _storage.write(key: _keyRefresh, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccess);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefresh);

  static Future<String?> getThemeMode() =>
      _storage.read(key: _keyThemeMode);

  static Future<void> saveThemeMode(String modeName) =>
      _storage.write(key: _keyThemeMode, value: modeName);

  static Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _keyAccess),
      _storage.delete(key: _keyRefresh),
    ]);
  }
}
