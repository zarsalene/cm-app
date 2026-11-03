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
  new(this._api, {required this._onUnauthorized})
    : super(const EscalationsState(loading: true));

  final CmApi _api;
  final void Function() _onUnauthorized;

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
