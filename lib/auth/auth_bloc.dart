import 'package:bloc/bloc.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// App start: restore the stored session, if any.
final class const AuthStarted() extends AuthEvent;

final class const LoginSubmitted(final String username, final String password)
    extends AuthEvent {
  @override
  List<Object> get props => [username, password];

  // Never print the password.
  @override
  String toString() => 'LoginSubmitted($username)';
}

final class const LogoutRequested() extends AuthEvent;

/// A protected call got a 401.
final class const SessionExpired() extends AuthEvent;

sealed class AuthState extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

final class const AuthUnknown() extends AuthState;

final class const Unauthenticated() extends AuthState;

final class const LoginInProgress() extends AuthState;

final class const LoginFailure(final String message) extends AuthState {
  @override
  List<Object> get props => [message];
}

final class const Authenticated(final String username) extends AuthState {
  @override
  List<Object> get props => [username];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  new(this._api, this._store, this._push) : super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<SessionExpired>(_onSessionExpired);
  }

  static const invalidLogin = 'Identifiant ou mot de passe incorrect';
  static const noConnection = 'Pas de connexion';
  static const otherError = 'Erreur, réessayez';

  final CmApi _api;
  final TokenStore _store;
  final PushService _push;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    String? token;
    String? username;
    try {
      token = await _store.read();
      username = await _store.readUsername();
    } on Exception {
      // Unreadable secure storage: ask for a new login.
    }
    emit(
      token != null && username != null
          ? Authenticated(username)
          : const Unauthenticated(),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const LoginInProgress());
    final username = event.username.trim();
    if (username.isEmpty || event.password.isEmpty) {
      emit(const LoginFailure(invalidLogin));
      return;
    }
    try {
      final session = await _api.login(username, event.password);
      await _store.write(session.token, session.username);
      emit(Authenticated(session.username));
    } on InvalidLoginException {
      emit(const LoginFailure(invalidLogin));
      return;
    } on NetworkException {
      emit(const LoginFailure(noConnection));
      return;
    } on Object {
      emit(const LoginFailure(otherError));
      return;
    }
    await _quietly(_push.subscribe);
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _quietly(_api.logout);
    await _store.delete();
    await _quietly(_push.unsubscribe);
    emit(const Unauthenticated());
  }

  Future<void> _onSessionExpired(
    SessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _store.delete();
    emit(const Unauthenticated());
    await _quietly(_push.unsubscribe);
  }

  // Push and server logout are best effort: never block login or logout.
  static Future<void> _quietly(Future<void> Function() call) async {
    try {
      await call();
    } on Object {
      // Ignored on purpose.
    }
  }
}
