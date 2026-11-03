import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
  FutureOr<Widget> Function(PushService push) builder,
) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  // The only place that picks the push service.
  PushService push;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    push = FcmPushService();
  } on Object {
    // No google-services.json (local build): the app runs without push.
    log('Firebase init failed: push disabled');
    push = const NoopPushService();
  }

  runApp(await builder(push));
}
