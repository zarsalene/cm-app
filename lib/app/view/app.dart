import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/router.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/l10n/l10n.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

class App extends StatelessWidget {
  /// Null dependencies get the real ones; tests pass fakes.
  const new({super.key, this.tokenStore, this.api, this.push});

  final TokenStore? tokenStore;
  final CmApi? api;
  final PushService? push;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TokenStore>(
          create: (_) => tokenStore ?? const TokenStore(),
        ),
        RepositoryProvider<CmApi>(
          create: (context) =>
              api ??
              CmApi(http.Client(), token: context.read<TokenStore>().read),
        ),
        RepositoryProvider<PushService>(
          // bootstrap passes the real service; null (tests) means no push.
          create: (_) => push ?? const NoopPushService(),
        ),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          context.read<CmApi>(),
          context.read<TokenStore>(),
          context.read<PushService>(),
        )..add(const AuthStarted()),
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const new();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final AuthRefresh _refresh;
  late final GoRouter _router;
  late final StreamSubscription<PushTarget> _opened;
  late final StreamSubscription<AuthState> _auth;

  /// A tapped alert that arrived before login; opened right after it.
  PushTarget? _pending;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>();
    final push = context.read<PushService>();
    _refresh = AuthRefresh(auth);
    _router = createRouter(auth, context.read<CmApi>(), push, _refresh);
    _opened = push.opened.listen((target) {
      if (auth.state is Authenticated) {
        _openChat(target);
      } else {
        _pending = target;
      }
    });
    var wasAuthenticated = auth.state is Authenticated;
    _auth = auth.stream.listen((state) {
      final isAuthenticated = state is Authenticated;
      if (isAuthenticated) {
        final target = _pending;
        _pending = null;
        if (target != null) _openChat(target);
      } else if (wasAuthenticated) {
        _pending = null; // Logout: never open a chat for the next login.
      }
      wasAuthenticated = isAuthenticated;
    });
  }

  void _openChat(PushTarget target) {
    // parsePushTarget allows only digits and known platforms: path is safe.
    _router.go('/chat/${target.platform}/${target.senderId}');
  }

  @override
  void dispose() {
    unawaited(_opened.cancel());
    unawaited(_auth.cancel());
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
