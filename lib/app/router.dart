import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/login_page.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:cm_app/chat/chat_page.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:cm_app/escalations/escalations_page.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Tells the router to re-run `redirect` on every [AuthBloc] state change.
class AuthRefresh extends ChangeNotifier {
  new(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// Where [state] allows the user to be, or null to stay at [location].
String? authRedirect(AuthState state, String location) {
  return switch (state) {
    AuthUnknown() => location == '/splash' ? null : '/splash',
    Authenticated() =>
      location == '/login' || location == '/splash' ? '/' : null,
    Unauthenticated() ||
    LoginInProgress() ||
    LoginFailure() => location == '/login' ? null : '/login',
  };
}

GoRouter createRouter(
  AuthBloc auth,
  CmApi api,
  PushService push,
  Listenable refresh,
) {
  void onUnauthorized() => auth.add(const SessionExpired());
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(auth.state, state.uri.path),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) {
            final cubit = EscalationsCubit(
              api,
              onUnauthorized: onUnauthorized,
              push: push,
            );
            unawaited(cubit.load());
            return cubit;
          },
          child: const EscalationsPage(),
        ),
        // Sub-route: `go('/chat/...')` from a push tap keeps the list below,
        // so back returns to it.
        routes: [
          GoRoute(
            path: 'chat/:platform/:senderId',
            builder: (context, state) => BlocProvider(
              create: (_) {
                final cubit = ChatCubit(
                  api,
                  state.pathParameters['senderId']!,
                  state.pathParameters['platform']!,
                  onUnauthorized: onUnauthorized,
                );
                unawaited(cubit.load());
                return cubit;
              },
              child: const ChatPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
