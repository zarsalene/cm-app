import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/view/app.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCmApi extends Mock implements CmApi;

class _MockTokenStore extends Mock implements TokenStore;

void main() {
  late ThemeModeService themeMode;
  late TokenStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeMode = ThemeModeService(await SharedPreferences.getInstance());
    store = _MockTokenStore();
    when(store.readRememberMe).thenAnswer((_) async => false);
  });

  Future<void> pumpShell(WidgetTester tester) => tester.pumpWidget(
    App(tokenStore: store, api: _MockCmApi(), themeMode: themeMode),
  );

  testWidgets('a theme change reaches the running app', (tester) async {
    await pumpShell(tester);
    await tester.pump(const Duration(seconds: 3));

    await themeMode.set(ThemeMode.dark);
    await tester.pump();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('going offline shows the banner and does not crash', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) async => ['none'],
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        null,
      ),
    );

    await pumpShell(tester);
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hors ligne'), findsOneWidget);
  });
}
