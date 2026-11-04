import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:cm_app/escalations/escalations_page.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCmApi extends Mock implements CmApi {}

class _MockPushService extends Mock implements PushService {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget _testWidget(EscalationsCubit cubit) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ThemeModeService>(
          create: (_) => ThemeModeService(SharedPreferences.getInstance() as SharedPreferences),
        ),
        RepositoryProvider<PushService>(
          create: (_) => _MockPushService(),
        ),
      ],
      child: BlocProvider<EscalationsCubit>.value(
        value: cubit,
        child: MaterialApp(home: EscalationsPage()),
      ),
    );
  }

  testWidgets(
    'Inbox sort newest first displays newest escalation at top',
    (tester) async {
      final api = _MockCmApi();
      when(api.escalations).thenAnswer((_) async => [
        Escalation(
          senderId: '1000000000001',
          platform: 'facebook',
          customerName: 'Alice Martin',
          reason: 'Probleme de livraison',
          escalatedAt: DateTime.now().subtract(const Duration(minutes: 60)),
          status: 'open',
        ),
        Escalation(
          senderId: '21650123456',
          platform: 'whatsapp',
          customerName: 'Bob Durant',
          reason: 'Demande de remboursement',
          escalatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          status: 'open',
        ),
      ]);

      final cubit = EscalationsCubit(api, onUnauthorized: () {});
      await cubit.load();

      await tester.pumpWidget(_testWidget(cubit));
      await tester.pumpAndSettle();

      final bob = find.text('Bob Durant');
      final alice = find.text('Alice Martin');
      expect(bob, findsOneWidget);
      expect(alice, findsOneWidget);

      final bobRect = tester.getTopLeft(bob);
      final aliceRect = tester.getTopLeft(alice);
      expect(bobRect.dy, lessThan(aliceRect.dy));
    },
  );

  testWidgets(
    'Inbox sort oldest first displays oldest escalation at top',
    (tester) async {
      final api = _MockCmApi();
      when(api.escalations).thenAnswer((_) async => [
        Escalation(
          senderId: '1000000000001',
          platform: 'facebook',
          customerName: 'Alice Martin',
          reason: 'Probleme de livraison',
          escalatedAt: DateTime.now().subtract(const Duration(minutes: 60)),
          status: 'open',
        ),
        Escalation(
          senderId: '21650123456',
          platform: 'whatsapp',
          customerName: 'Bob Durant',
          reason: 'Demande de remboursement',
          escalatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          status: 'open',
        ),
      ]);

      final cubit = EscalationsCubit(api, onUnauthorized: () {});
      await cubit.load();

      await tester.pumpWidget(_testWidget(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Strings.sortOldestFirst));
      await tester.pumpAndSettle();

      final alice = find.text('Alice Martin');
      final bob = find.text('Bob Durant');
      expect(alice, findsOneWidget);
      expect(bob, findsOneWidget);

      final aliceRect = tester.getTopLeft(alice);
      final bobRect = tester.getTopLeft(bob);
      expect(aliceRect.dy, lessThan(bobRect.dy));
    },
  );

  testWidgets(
    'Inbox channel filter shows only selected channel',
    (tester) async {
      final api = _MockCmApi();
      when(api.escalations).thenAnswer((_) async => [
        Escalation(
          senderId: '1000000000001',
          platform: 'facebook',
          customerName: 'Alice Martin',
          reason: 'Probleme de livraison',
          escalatedAt: DateTime.now(),
          status: 'open',
        ),
        Escalation(
          senderId: '21650123456',
          platform: 'whatsapp',
          customerName: 'Bob Durant',
          reason: 'Demande de remboursement',
          escalatedAt: DateTime.now(),
          status: 'open',
        ),
      ]);

      final cubit = EscalationsCubit(api, onUnauthorized: () {});
      await cubit.load();

      await tester.pumpWidget(_testWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('Bob Durant'), findsOneWidget);

      await tester.tap(find.text(Strings.whatsapp));
      await tester.pumpAndSettle();

      expect(find.text('Bob Durant'), findsOneWidget);
      expect(find.text('Alice Martin'), findsNothing);
    },
  );

  testWidgets(
    'Inbox search filters by customer name',
    (tester) async {
      final api = _MockCmApi();
      when(api.escalations).thenAnswer((_) async => [
        Escalation(
          senderId: '1000000000001',
          platform: 'facebook',
          customerName: 'Alice Martin',
          reason: 'Probleme de livraison',
          escalatedAt: DateTime.now(),
          status: 'open',
        ),
        Escalation(
          senderId: '21650123456',
          platform: 'whatsapp',
          customerName: 'Bob Durant',
          reason: 'Demande de remboursement',
          escalatedAt: DateTime.now(),
          status: 'open',
        ),
      ]);

      final cubit = EscalationsCubit(api, onUnauthorized: () {});
      await cubit.load();

      await tester.pumpWidget(_testWidget(cubit));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pumpAndSettle();

      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('Bob Durant'), findsNothing);
    },
  );
}
