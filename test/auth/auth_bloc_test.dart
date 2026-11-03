import 'package:bloc_test/bloc_test.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCmApi extends Mock implements CmApi;

class _MockTokenStore extends Mock implements TokenStore;

class _MockPushService extends Mock implements PushService;

void main() {
  group(AuthBloc, () {
    late CmApi api;
    late TokenStore store;
    late PushService push;

    setUp(() {
      api = _MockCmApi();
      store = _MockTokenStore();
      push = _MockPushService();
      when(() => store.delete()).thenAnswer((_) async {});
      when(() => push.unsubscribe()).thenAnswer((_) async {});
    });

    group('$LoginSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [$LoginInProgress, $LoginFailure] when the server rejects '
        'the credentials',
        setUp: () =>
            when(() => api.login(any(), any()))
                .thenThrow(const InvalidLoginException()),
        build: () => AuthBloc(api, store, push),
        act: (bloc) => bloc.add(const LoginSubmitted('cm', 'wrong')),
        expect: () => const [
          LoginInProgress(),
          LoginFailure('Identifiant ou mot de passe incorrect'),
        ],
      );
    });

    group('$SessionExpired', () {
      blocTest<AuthBloc, AuthState>(
        'emits [$Unauthenticated] and deletes the token when authenticated',
        build: () => AuthBloc(api, store, push),
        seed: () => const Authenticated('cm'),
        act: (bloc) => bloc.add(const SessionExpired()),
        expect: () => const [Unauthenticated()],
        verify: (_) {
          verify(() => store.delete()).called(1);
          verifyNever(() => api.logout());
        },
      );
    });
  });
}
