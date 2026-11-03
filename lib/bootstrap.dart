import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
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
