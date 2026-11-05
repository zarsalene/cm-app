import 'package:bloc/bloc.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.languageCode,
    required this.pushAvailable,
  });

  factory SettingsState.initial(ThemeModeService theme, PushService push) {
    return SettingsState(
      themeMode: theme.mode,
      notificationsEnabled: true,
      languageCode: 'fr',
      pushAvailable: push.available,
    );
  }

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String languageCode;
  final bool pushAvailable;

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    languageCode,
    pushAvailable,
  ];

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? languageCode,
    bool? pushAvailable,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    languageCode: languageCode ?? this.languageCode,
    pushAvailable: pushAvailable ?? this.pushAvailable,
  );
}

sealed class SettingsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

final class const ThemeChanged({required this.mode}) extends SettingsEvent {
  final ThemeMode mode;
  @override
  List<Object> get props => [mode];
}

final class const NotificationsToggled({required this.enabled})
    extends SettingsEvent {
  final bool enabled;
  @override
  List<Object> get props => [enabled];
}

final class const LanguageChanged({required this.code}) extends SettingsEvent {
  final String code;
  @override
  List<Object> get props => [code];
}

final class const CheckNotifications() extends SettingsEvent {}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.theme, required this.push, required this.auth})
    : super(SettingsState.initial(theme, push));

  final ThemeModeService theme;
  final PushService push;
  final AuthBloc auth;

  Future<void> onThemeChanged(ThemeMode mode) async {
    await theme.set(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> onNotificationsToggled(bool enabled) async {
    emit(state.copyWith(notificationsEnabled: enabled));
    try {
      if (enabled) {
        await push.subscribe();
      } else {
        await push.unsubscribe();
      }
    } on Object {
      // Fire-and-forget from the switch: a rethrow would be an unhandled
      // error. The switch snaps back instead.
      emit(state.copyWith(notificationsEnabled: !enabled));
    }
  }

  Future<void> onLanguageChanged(String code) async {
    emit(state.copyWith(languageCode: code));
  }

  Future<void> checkNotifications() async {
    bool enabled;
    try {
      enabled = await push.notificationsEnabled;
    } on Object {
      enabled = true;
    }
    emit(
      state.copyWith(
        notificationsEnabled: enabled,
        pushAvailable: push.available,
      ),
    );
  }

  void onLogoutRequested() => auth.add(const LogoutRequested());
  // LogoutRequested is defined in auth_bloc.dart and extends AuthEvent.
}
