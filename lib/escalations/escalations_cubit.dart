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
  final bool offline = false,
}) extends Equatable {
  /// Every call sets `error` again: a plain copy clears it.
  EscalationsState copyWith({
    List<Escalation>? items,
    bool? loading,
    String? error,
    bool? notificationsOff,
    bool? offline,
  }) => EscalationsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    error: error,
    notificationsOff: notificationsOff ?? this.notificationsOff,
    offline: offline ?? this.offline,
  );

  @override
  List<Object?> get props => [items, loading, error, notificationsOff, offline];
}

Stream<void> _every30Seconds() =>
    Stream<void>.periodic(const Duration(seconds: 30));

class EscalationsCubit extends Cubit<EscalationsState> {
  /// Each foreground push from [_push] reloads the list. [_ticks] makes the
  /// polling clock (tests pass their own).
  new(
    this._api, {
    required this._onUnauthorized,
    this._push = const NoopPushService(),
    this._ticks = _every30Seconds,
  }) : super(const EscalationsState(loading: true)) {
    _alerts = _push.foreground.listen((_) => unawaited(load()));
  }

  final CmApi _api;
  final void Function() _onUnauthorized;
  final PushService _push;
  final Stream<void> Function() _ticks;
  late final StreamSubscription<void> _alerts;
  StreamSubscription<void>? _poll;

  /// Number of the newest load: an older response is dropped.
  int _seq = 0;
  int _inFlight = 0;
  int _failures = 0;

  @override
  Future<void> close() async {
    // Cancel first: no load() may run on a closed cubit.
    await _alerts.cancel();
    await _poll?.cancel();
    await super.close();
  }

  /// Loads the list with a spinner. The server sorts it: open first, newest
  /// first.
  Future<void> load() => _fetch(silent: false);

  /// Silent load for polling: no spinner, the list stays on error. Skipped
  /// while another load runs.
  Future<void> refresh() async {
    if (_inFlight > 0 || isClosed) return;
    await _fetch(silent: true);
  }

  /// Refreshes on every tick until [stopPolling]. Call only while resumed.
  void startPolling() {
    if (isClosed) return;
    _poll ??= _ticks().listen((_) => unawaited(refresh()));
  }

  void stopPolling() {
    unawaited(_poll?.cancel());
    _poll = null;
  }

  Future<void> _fetch({required bool silent}) async {
    final seq = ++_seq;
    if (!silent) emit(state.copyWith(loading: true));
    _inFlight++;
    try {
      final items = await _api.escalations();
      _failures = 0;
      if (!isClosed && seq == _seq) {
        emit(state.copyWith(items: items, loading: false, offline: false));
      }
    } on UnauthorizedException {
      _onUnauthorized();
      if (!isClosed && seq == _seq) {
        emit(state.copyWith(loading: false, error: state.error));
      }
    } on Object catch (e) {
      // Two failures in a row: the user sees that alerts may be late.
      _failures++;
      if (!isClosed && seq == _seq) {
        emit(
          state.copyWith(
            loading: false,
            error: silent ? state.error : Strings.errorFor(e),
            offline: _failures >= 2,
          ),
        );
      }
    } finally {
      _inFlight--;
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
