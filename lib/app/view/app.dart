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
          // shortcut: no-op until Task 9 adds the real push service.
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

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>();
    _refresh = AuthRefresh(auth);
    _router = createRouter(auth, context.read<CmApi>(), _refresh);
  }

  @override
  void dispose() {
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
