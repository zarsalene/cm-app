import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:cm_app/core/error/error_boundary.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBlocObserver extends BlocObserver {
  const new();

  // Types only: states hold user names, sender ids and messages.
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      log('${bloc.runtimeType} -> ${change.nextState.runtimeType}');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, ${error.runtimeType})');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(
  FutureOr<Widget> Function(PushService push, ThemeModeService themeMode)
  builder,
) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  // Async errors outside the widget tree (a failed fire-and-forget call)
  // would otherwise end up unlogged. `true` = handled, the app keeps running.
  PlatformDispatcher.instance.onError = (error, stack) {
    log('Uncaught: ${error.runtimeType}', stackTrace: stack);
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  installGlobalErrorWidget();

  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final themeMode = ThemeModeService(prefs);

  // The only place that picks the push service.
  PushService push;
  try {
    await Firebase.initializeApp();
    push = FcmPushService();
  } on Object {
    // No google-services.json (local build): the app runs without push.
    log('Firebase init failed: push disabled');
    push = const NoopPushService();
  }

  runApp(await builder(push, themeMode));
}
