import 'package:cm_app/app/app.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/counter/counter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStore extends Mock implements TokenStore;

void main() {
  group('App', () {
    late TokenStore store;

    setUp(() {
      store = _MockTokenStore();
      when(() => store.read()).thenAnswer((_) async => 'tok');
      when(() => store.readUsername()).thenAnswer((_) async => 'cm');
    });

    testWidgets('renders CounterPage when a session is stored', (tester) async {
      await tester.pumpWidget(App(tokenStore: store));
      await tester.pump();
      expect(find.byType(CounterPage), findsOneWidget);
    });
  });
}
