import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:equatable/equatable.dart';

final class const EscalationsState({
  final List<Escalation> items = const [],
  final bool loading = false,
  final String? error,
  final bool notificationsOff = false,
}) extends Equatable {
  /// Every call sets `error` again: a plain copy clears it.
  EscalationsState copyWith({
    List<Escalation>? items,
    bool? loading,
    String? error,
    bool? notificationsOff,
  }) => EscalationsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: error,
    notificationsOff: notificationsOff ?? this.notificationsOff,
  );

  @override
  List<Object?> get props => [items, loading, error, notificationsOff];
}

class EscalationsCubit extends Cubit<EscalationsState> {
  /// Each foreground push from [_push] reloads the list.
  new(
    this._api, {
    required this._onUnauthorized,
    this._push = const NoopPushService(),
  }) : super(const EscalationsState(loading: true)) {
    _alerts = _push.foreground.listen((_) => unawaited(load()));
  }

  final CmApi _api;
  final void Function() _onUnauthorized;
  final PushService _push;
  late final StreamSubscription<void> _alerts;

  /// Number of the newest load: an older response is dropped.
  int _seq = 0;

  @override
  Future<void> close() async {
    // Cancel first: no load() may run on a closed cubit.
    await _alerts.cancel();
    await super.close();
  }

  /// Loads the list. The server already sorts it: open first, newest first.
  Future<void> load() async {
    final seq = ++_seq;
    emit(state.copyWith(loading: true));
    try {
      final items = await _api.escalations();
      if (!isClosed && seq == _seq) {
        emit(state.copyWith(items: items, loading: false));
      }
    } on UnauthorizedException {
      _onUnauthorized();
      if (!isClosed && seq == _seq) emit(state.copyWith(loading: false));
    } on Object catch (e) {
      if (!isClosed && seq == _seq) {
        emit(state.copyWith(loading: false, error: Strings.errorFor(e)));
      }
    }
  }

  /// Reads the notification permission; the page shows a notice when off.
  Future<void> checkNotifications() async {
    bool enabled;
    try {
      enabled = await _push.notificationsEnabled;
    } on Object {
      enabled = true; // Unknown: no false alarm.
    }
    if (!isClosed) {
      emit(state.copyWith(notificationsOff: !enabled, error: state.error));
    }
  }
}
