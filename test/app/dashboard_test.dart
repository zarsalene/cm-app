import 'package:cm_app/app/dashboard_page.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
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
        child: MaterialApp(home: DashboardPage()),
      ),
    );
  }

  testWidgets(
    'Dashboard shows priority queue with oldest open escalation first',
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

      expect(find.text(Strings.priorityQueue), findsOneWidget);

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
    'Dashboard shows handled today count',
    (tester) async {
      final api = _MockCmApi();
      final today = DateTime.now();
      when(api.escalations).thenAnswer((_) async => [
        Escalation(
          senderId: '1000000000001',
          platform: 'facebook',
          customerName: 'Alice Martin',
          reason: 'Probleme de livraison',
          escalatedAt: today.subtract(const Duration(hours: 2)),
          status: 'closed',
        ),
        Escalation(
          senderId: '21650123456',
          platform: 'whatsapp',
          customerName: 'Bob Durant',
          reason: 'Demande de remboursement',
          escalatedAt: today.subtract(const Duration(days: 1)),
          status: 'closed',
        ),
      ]);

      final cubit = EscalationsCubit(api, onUnauthorized: () {});
      await cubit.load();

      await tester.pumpWidget(_testWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Traitees aujourd hui'), findsOneWidget);
    },
  );

  testWidgets(
    'Dashboard shows empty state when no escalations',
    (tester) async {
      final api = _MockCmApi();
      when(api.escalations).thenAnswer((_) async => []);

      final cubit = EscalationsCubit(api, onUnauthorized: () {});
      await cubit.load();

      await tester.pumpWidget(_testWidget(cubit));
      await tester.pumpAndSettle();

      expect(find.text(Strings.noEscalations), findsOneWidget);
    },
  );
}
