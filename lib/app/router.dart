import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/dashboard_page.dart';
import 'package:cm_app/app/splash_page.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/login_page.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:cm_app/chat/chat_page.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:cm_app/escalations/escalations_page.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// Holds the splash for a minimum time. Never holds an alert: [release]
/// ends the hold at once (push tap, reduced motion).
class SplashGate extends ChangeNotifier {
  new({required bool hold, Duration minimum = const Duration(seconds: 1)})
    : _done = !hold {
    if (hold) {
      // Counted from the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_done) _timer = Timer(minimum, release);
      });
    }
  }

  bool _done;
  Timer? _timer;

  bool get done => _done;

  void release() {
    _timer?.cancel();
    if (_done) return;
    _done = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Where [state] allows the user to be, or null to stay at [location].
/// Leaving `/splash` also needs [splashDone].
String? authRedirect(
  AuthState state,
  String location, {
  bool splashDone = true,
}) {
  final onSplash = location == '/splash';
  return switch (state) {
    AuthUnknown() => onSplash ? null : '/splash',
    _ when onSplash && !splashDone => null,
    Authenticated() => location == '/login' || onSplash ? '/' : null,
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
  SplashGate splash,
) {
  void onUnauthorized() => auth.add(const SessionExpired());
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(auth.state, state.uri.path, splashDone: splash.done),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
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
          child: const DashboardPage(),
        ),
      ),
      GoRoute(
        path: '/escalations',
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
      ),
      GoRoute(
        path: '/chat/:platform/:senderId',
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
  );
}
