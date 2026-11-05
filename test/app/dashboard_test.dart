import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/dashboard_page.dart';
import 'package:cm_app/app/dashboard_strings.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/inbox/inbox_cubit.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCmApi extends Mock implements CmApi {}

class _MockPushService extends Mock implements PushService {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget testWidget(InboxCubit cubit) {
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(const Authenticated('Sarah'));
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ThemeModeService>(
          create: (_) => ThemeModeService(
            SharedPreferences.getInstance() as SharedPreferences,
          ),
        ),
        RepositoryProvider<PushService>(create: (_) => _MockPushService()),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: auth,
        child: BlocProvider<InboxCubit>.value(
          value: cubit,
          child: const MaterialApp(home: DashboardPage()),
        ),
      ),
    );
  }

  Conversation conversation({
    required String senderId,
    required String platform,
    required String name,
    required String status,
    required ChatMode mode,
    required DateTime at,
    String reason = 'Probleme de livraison',
  }) => Conversation(
    senderId: senderId,
    platform: platform,
    customerName: name,
    lastMessage: reason,
    lastSeen: at,
    mode: mode,
    status: status,
    reason: reason,
    escalatedAt: at,
  );

  testWidgets(
    'Dashboard shows priority queue with oldest open conversation first',
    (tester) async {
      final api = _MockCmApi();
      final now = DateTime.now();
      when(api.conversations).thenAnswer(
        (_) async => [
          conversation(
            senderId: '1000000000001',
            platform: 'facebook',
            name: 'Alice Martin',
            status: 'open',
            mode: ChatMode.human,
            at: now.subtract(const Duration(minutes: 60)),
          ),
          conversation(
            senderId: '21650123456',
            platform: 'whatsapp',
            name: 'Bob Durant',
            status: 'open',
            mode: ChatMode.human,
            at: now.subtract(const Duration(minutes: 10)),
            reason: 'Demande de remboursement',
          ),
        ],
      );

      // Tall phone screen: both cards sit below the stat tiles.
      tester.view
        ..physicalSize = const Size(1170, 4200)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final cubit = InboxCubit(api, onUnauthorized: () {});
      unawaited(cubit.load());

      await tester.pumpWidget(testWidget(cubit));
      await _settle(tester);

      expect(find.text(DashboardStrings.priorityTitle), findsOneWidget);

      // Names also show in "Activité récente" below: `.first` is the card of
      // the priority queue, which comes first in the list.
      final alice = find.text('Alice Martin').first;
      final bob = find.text('Bob Durant').first;
      expect(alice, findsOneWidget);
      expect(bob, findsOneWidget);

      final aliceRect = tester.getTopLeft(alice);
      final bobRect = tester.getTopLeft(bob);
      expect(aliceRect.dy, lessThan(bobRect.dy));
    },
  );

  testWidgets('Dashboard shows handled today count', (tester) async {
    final api = _MockCmApi();
    final today = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          status: 'closed',
          mode: ChatMode.bot,
          at: today.subtract(const Duration(hours: 2)),
        ),
        conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          status: 'closed',
          mode: ChatMode.bot,
          at: today.subtract(const Duration(days: 1)),
          reason: 'Demande de remboursement',
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    unawaited(cubit.load());

    await tester.pumpWidget(testWidget(cubit));
    await _settle(tester);

    expect(find.text(DashboardStrings.handledToday), findsOneWidget);
  });

  testWidgets('Dashboard shows empty state when there is no conversation', (
    tester,
  ) async {
    final api = _MockCmApi();
    when(api.conversations).thenAnswer((_) async => []);

    final cubit = InboxCubit(api, onUnauthorized: () {});
    unawaited(cubit.load());

    await tester.pumpWidget(testWidget(cubit));
    await _settle(tester);

    expect(find.text(Strings.noConversations), findsOneWidget);
  });

  testWidgets('Dashboard counts bot conversations separately', (tester) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          status: 'open',
          mode: ChatMode.human,
          at: now,
        ),
        conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          status: 'active',
          mode: ChatMode.bot,
          at: now,
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    unawaited(cubit.load());

    await tester.pumpWidget(testWidget(cubit));
    await _settle(tester);

    expect(find.text(DashboardStrings.byBot), findsOneWidget);
  });
}
