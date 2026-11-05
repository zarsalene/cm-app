import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session token and username in secure storage.
/// The password is never stored.
class TokenStore {
  /// Creates a [TokenStore].
  const new([this._storage = const FlutterSecureStorage()]);

  static const _tokenKey = 'cm_token';
  static const _usernameKey = 'cm_username';
  static const _rememberMeKey = 'cm_remember_me';
  static const _nameCacheKey = 'cm_name_cache_';

  final FlutterSecureStorage _storage;

  /// Tests whether secure storage can write, read, and delete.
  /// Returns `true` when credentials can be saved on this device.
  Future<bool> testStorage() async {
    try {
      const testKey = 'cm_storage_test';
      await _storage.write(key: testKey, value: 'ok');
      final value = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      if (kDebugMode) log('TokenStore.testStorage: $value');
      return value == 'ok';
    } on Object {
      if (kDebugMode) log('TokenStore.testStorage: failed');
      return false;
    }
  }

  /// The stored bearer token, or null.
  Future<String?> read() async {
    try {
      final value = await _storage.read(key: _tokenKey);
      // Never log the token itself.
      if (kDebugMode) log('TokenStore.read: found=${value != null}');
      return value;
    } on Object {
      if (kDebugMode) log('TokenStore.read: failed');
      return null;
    }
  }

  /// The stored username, or null.
  Future<String?> readUsername() async {
    try {
      final value = await _storage.read(key: _usernameKey);
      if (kDebugMode) log('TokenStore.readUsername: found=${value != null}');
      return value;
    } on Object {
      if (kDebugMode) log('TokenStore.readUsername: failed');
      return null;
    }
  }

  /// Whether "remember me" was selected at last login.
  Future<bool> readRememberMe() async {
    try {
      final value = await _storage.read(key: _rememberMeKey);
      final result = value == 'true';
      if (kDebugMode) log('TokenStore.readRememberMe: $result');
      return result;
    } on Object {
      if (kDebugMode) log('TokenStore.readRememberMe: failed');
      return false;
    }
  }

  /// Saves the token, the username and the remember-me flag of a new session.
  /// Throws when storage fails: every call needs the saved token, so a login
  /// that was not saved must not look like a success.
  Future<void> write({
    required String token,
    required String username,
    required bool rememberMe,
  }) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _usernameKey, value: username);
      await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
      if (kDebugMode) log('TokenStore.write: saved');
    } on Object {
      if (kDebugMode) log('TokenStore.write: failed');
      rethrow;
    }
  }

  /// Removes the session.
  Future<void> delete() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _usernameKey);
      await _storage.delete(key: _rememberMeKey);
      if (kDebugMode) log('TokenStore.delete: session cleared');
    } on Object {
      if (kDebugMode) log('TokenStore.delete: failed');
    }
  }

  /// Caches a customer name for [senderId] so it can be reused when the API
  /// doesn't send a name. Called whenever the API returns a known name.
  Future<void> cacheCustomerName(String senderId, String name) async {
    try {
      await _storage.write(key: '${_nameCacheKey}$senderId', value: name);
      if (kDebugMode) log('TokenStore.cacheCustomerName: saved');
    } on Object {
      if (kDebugMode) log('TokenStore.cacheCustomerName: failed');
    }
  }

  /// Reads a previously cached customer name for [senderId], or null.
  Future<String?> readCustomerName(String senderId) async {
    try {
      final value = await _storage.read(key: '${_nameCacheKey}$senderId');
      if (kDebugMode)
        log('TokenStore.readCustomerName: found=${value != null}');
      return value;
    } on Object {
      if (kDebugMode) log('TokenStore.readCustomerName: failed');
      return null;
    }
  }
}
