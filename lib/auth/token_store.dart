import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session token and username in secure storage.
/// The password is never stored.
class TokenStore {
  /// Creates a [TokenStore].
  const new([this._storage = const FlutterSecureStorage()]);

  static const _tokenKey = 'cm_token';
  static const _usernameKey = 'cm_username';
  static const _rememberMeKey = 'cm_remember_me';

  final FlutterSecureStorage _storage;

  /// The stored bearer token, or null.
  Future<String?> read() => _storage.read(key: _tokenKey);

  /// The stored username, or null.
  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  /// Whether "remember me" was selected at last login.
  Future<bool> readRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  /// Saves the token, the username and the remember-me flag of a new session.
  Future<void> write({
    required String token,
    required String username,
    required bool rememberMe,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
  }

  /// Removes the session.
  Future<void> delete() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _rememberMeKey);
  }
}
