import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session token and username in secure storage.
/// The password is never stored.
class TokenStore {
  /// Creates a [TokenStore].
  const new([this._storage = const FlutterSecureStorage()]);

  static const _tokenKey = 'cm_token';
  static const _usernameKey = 'cm_username';

  final FlutterSecureStorage _storage;

  /// The stored bearer token, or null.
  Future<String?> read() => _storage.read(key: _tokenKey);

  /// The stored username, or null.
  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  /// Saves the token and the username of a new session.
  Future<void> write(String token, String username) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  /// Removes the session.
  Future<void> delete() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
