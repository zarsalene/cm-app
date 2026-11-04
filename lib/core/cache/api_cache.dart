import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Thin in-memory cache for API responses.
///
/// Entries expire after [ttl]. Stale entries are lazily evicted on read.
/// Use this for read-only data (escalations list) that can be served from
/// cache while a refresh is in flight.
class ApiCache {
  /// Creates an [ApiCache] with the given [ttl] (default 5 minutes).
  ApiCache({Duration ttl = const Duration(minutes: 5)}) : _ttl = ttl;

  final Duration _ttl;
  final Map<String, _CacheEntry> _store = {};

  /// Reads [key] from cache. Returns null when absent or expired.
  dynamic read(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _store.remove(key);
      return null;
    }
    return entry.data;
  }

  /// Writes [data] under [key], overwriting any existing entry.
  void write(String key, dynamic data) {
    _store[key] = _CacheEntry(data: data, expiry: DateTime.now().add(_ttl));
  }

  /// Removes [key] from the cache.
  void delete(String key) => _store.remove(key);

  /// Clears all entries.
  void clear() => _store.clear();

  /// Number of live (non-expired) entries.
  int get size {
    var count = 0;
    final now = DateTime.now();
    for (final entry in _store.values) {
      if (now.isBefore(entry.expiry)) count++;
    }
    return count;
  }

  /// Prints a debug summary of live entries.
  void debugDump() {
    if (!kDebugMode) return;
    final now = DateTime.now();
    for (final entry in _store.entries) {
      if (now.isAfter(entry.value.expiry)) continue;
      log('cache[${entry.key}] ttl=${entry.value.expiry.difference(now).inSeconds}s');
    }
  }
}

class _CacheEntry {
  const _CacheEntry({required this.data, required this.expiry});
  final dynamic data;
  final DateTime expiry;
}

/// Encodes/decodes JSON for cache storage.
class JsonCache {
  JsonCache(this._inner);

  final ApiCache _inner;

  T? read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _inner.read(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      return fromJson(json);
    } on Object {
      return null;
    }
  }

  void write<T>(String key, T data, String Function(dynamic) toJson) {
    _inner.write(key, jsonEncode(toJson(data)));
  }
}
