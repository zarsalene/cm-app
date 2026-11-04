import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/router.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/core/connectivity/connectivity_service.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/demo/demo.dart';
import 'package:cm_app/demo/fake_cm_api.dart';
import 'package:cm_app/l10n/l10n.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class App extends StatelessWidget {
  /// Null dependencies get the real ones; tests pass fakes.
  const new({
    super.key,
    this.tokenStore,
    this.api,
    this.push,
    required this.themeMode,
  });

  final TokenStore? tokenStore;
  final CmApi? api;
  final PushService? push;
  final ThemeModeService themeMode;

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
              (kDemo
                  ? FakeCmApi()
                  : CmApi(
                      http.Client(),
                      token: context.read<TokenStore>().read,
                    )),
        ),
        RepositoryProvider<PushService>(
          // bootstrap passes the real service; null (tests) means no push.
          create: (_) =>
              kDemo ? const NoopPushService() : push ?? const NoopPushService(),
        ),
        RepositoryProvider<ThemeModeService>(create: (_) => themeMode),
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
  /// A tap older than this is stale: the alert may be handled already.
  static const _pendingMaxAge = Duration(minutes: 30);

  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final AuthRefresh _refresh;
  late final SplashGate _splash;
  late final GoRouter _router;
  late final StreamSubscription<PushTarget> _opened;
  late final StreamSubscription<void> _foreground;
  late final StreamSubscription<AuthState> _auth;

  /// A tapped alert that arrived before login; opened right after it.
  PushTarget? _pending;
  DateTime? _pendingAt;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>();
    final push = context.read<PushService>();
    _refresh = AuthRefresh(auth);
    // No hold when auth is known at first frame or motion is reduced.
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    _splash = SplashGate(hold: auth.state is AuthUnknown && !reduceMotion);
    _router = createRouter(
      auth,
      context.read<CmApi>(),
      push,
      Listenable.merge([_refresh, _splash]),
      _splash,
    );
    _opened = push.opened.listen((target) {
      if (auth.state is Authenticated) {
        _openChat(target);
      } else {
        _pending = target;
        _pendingAt = DateTime.now();
        _splash.release();
      }
    });
    _foreground = push.foreground.listen((_) {
      if (auth.state is Authenticated) _showAlert();
    });
    var wasAuthenticated = auth.state is Authenticated;
    _auth = auth.stream.listen((state) {
      final isAuthenticated = state is Authenticated;
      if (isAuthenticated) {
        final target = _pending;
        final at = _pendingAt;
        _pending = null;
        _pendingAt = null;
        if (target != null &&
            at != null &&
            DateTime.now().difference(at) < _pendingMaxAge) {
          _openChat(target);
        }
      } else if (wasAuthenticated) {
        // Logout: never open a chat for the next login.
        _pending = null;
        _pendingAt = null;
      }
      wasAuthenticated = isAuthenticated;
    });
  }

  void _openChat(PushTarget target) {
    // parsePushTarget allows only digits and known platforms: path is safe.
    _router.go('/chat/${target.platform}/${target.senderId}');
  }

  /// Android shows no system notification while the app is open.
  void _showAlert() {
    try {
      _messenger.currentState?.showSnackBar(
        SnackBar(
          content: Semantics(
            liveRegion: true,
            child: const Text(Strings.newAlert),
          ),
          action: SnackBarAction(
            label: Strings.openChat,
            onPressed: () {
              // The user can tap the alert to open the chat via push handling.
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on Object {
      // No messenger or no Scaffold yet: the list reload still runs.
    }
  }

  @override
  void dispose() {
    unawaited(_opened.cancel());
    unawaited(_foreground.cancel());
    unawaited(_auth.cancel());
    _router.dispose();
    _refresh.dispose();
    _splash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.read<ThemeModeService>();
    return _ConnectivityOverlay(
      child: MaterialApp.router(
        title: Strings.appName,
        scaffoldMessengerKey: _messenger,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode.mode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        builder: kDemo
            ? (context, child) => Banner(
                message: 'MODE D\u00c9MO',
                location: BannerLocation.topEnd,
                child: child,
              )
            : null,
      ),
    );
  }
}

/// Shows a persistent offline banner when the device has no network.
class _ConnectivityOverlay extends StatefulWidget {
  const _ConnectivityOverlay({required this.child});

  final Widget child;

  @override
  State<_ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<_ConnectivityOverlay> {
  bool _online = true;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  @override
  void initState() {
    super.initState();
    _sub = ConnectivityService().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted && online != _online) setState(() => _online = online);
    });
    unawaited(
      ConnectivityService().isConnected.then((online) {
        if (mounted) setState(() => _online = online);
      }),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_online) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.amber,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Hors ligne \u2014 vous sont d\u00e9connect\u00e9(e)',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
