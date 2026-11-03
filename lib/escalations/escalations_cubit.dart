import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/strings.dart';
import 'package:equatable/equatable.dart';

final class const EscalationsState({
  final List<Escalation> items = const [],
  final bool loading = false,
  final String? error,
}) extends Equatable {
  @override
  List<Object?> get props => [items, loading, error];
}

class EscalationsCubit extends Cubit<EscalationsState> {
  /// Each [alerts] event (a push received in the foreground) reloads the list.
  new(
    this._api, {
    required this._onUnauthorized,
    Stream<void> alerts = const Stream.empty(),
  }) : super(const EscalationsState(loading: true)) {
    _alerts = alerts.listen((_) => unawaited(load()));
  }

  final CmApi _api;
  final void Function() _onUnauthorized;
  late final StreamSubscription<void> _alerts;

  @override
  Future<void> close() async {
    // Cancel first: no load() may run on a closed cubit.
    await _alerts.cancel();
    await super.close();
  }

  /// Loads the list. The server already sorts it: open first, newest first.
  Future<void> load() async {
    emit(EscalationsState(items: state.items, loading: true));
    try {
      final items = await _api.escalations();
      if (!isClosed) emit(EscalationsState(items: items));
    } on UnauthorizedException {
      _onUnauthorized();
      if (!isClosed) emit(EscalationsState(items: state.items));
    } on Object catch (e) {
      if (!isClosed) {
        emit(EscalationsState(items: state.items, error: Strings.errorFor(e)));
      }
    }
  }
}
