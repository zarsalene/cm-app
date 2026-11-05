import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme mode choice across restarts.
///
/// Modes:
///   - `system`  — follow the OS setting
///   - `light`   — always light
///   - `dark`    — always dark
class ThemeModeService extends ChangeNotifier {
  static const _key = 'cm_theme_mode';

  ThemeModeService(this._prefs);

  final SharedPreferences _prefs;

  /// Returns the stored [ThemeMode], defaulting to `system`.
  ThemeMode get mode {
    final raw = _prefs.getString(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Persists [mode]. No-op if the value is unchanged.
  Future<void> set(ThemeMode mode) async {
    if (this.mode == mode) return;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_key, value);
    // The app listens: without this the new theme shows only after a restart.
    notifyListeners();
  }

  /// The [Brightness] implied by [mode] given the platform brightness.
  Brightness brightness(BuildContext context) {
    final mode = this.mode;
    if (mode != ThemeMode.system) {
      return mode == ThemeMode.light ? Brightness.light : Brightness.dark;
    }
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}
