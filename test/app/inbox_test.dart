import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/inbox/inbox_cubit.dart';
import 'package:cm_app/inbox/inbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCmApi extends Mock implements CmApi {}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _testWidget(InboxCubit cubit) => BlocProvider<InboxCubit>.value(
  value: cubit,
  child: const MaterialApp(home: InboxPage()),
);

Conversation _conversation({
  required String senderId,
  required String platform,
  required String name,
  required DateTime at,
  ChatMode mode = ChatMode.human,
  String status = 'open',
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
  escalatedAt: status == 'open' ? at : null,
);

void main() {
  testWidgets('Inbox sort newest first displays newest conversation at top', (
    tester,
  ) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        _conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          at: now.subtract(const Duration(minutes: 60)),
        ),
        _conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          at: now.subtract(const Duration(minutes: 10)),
          reason: 'Demande de remboursement',
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    final bob = find.text('Bob Durant');
    final alice = find.text('Alice Martin');
    expect(bob, findsOneWidget);
    expect(alice, findsOneWidget);

    final bobRect = tester.getTopLeft(bob);
    final aliceRect = tester.getTopLeft(alice);
    expect(bobRect.dy, lessThan(aliceRect.dy));
  });

  testWidgets('Inbox sort oldest first displays oldest conversation at top', (
    tester,
  ) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        _conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          at: now.subtract(const Duration(minutes: 60)),
        ),
        _conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          at: now.subtract(const Duration(minutes: 10)),
          reason: 'Demande de remboursement',
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    await tester.tap(find.text(Strings.sortOldestFirst));
    await _settle(tester);

    final alice = find.text('Alice Martin');
    final bob = find.text('Bob Durant');
    expect(alice, findsOneWidget);
    expect(bob, findsOneWidget);

    final aliceRect = tester.getTopLeft(alice);
    final bobRect = tester.getTopLeft(bob);
    expect(aliceRect.dy, lessThan(bobRect.dy));
  });

  testWidgets('Inbox channel filter shows only the selected channel', (
    tester,
  ) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        _conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          at: now,
        ),
        _conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          at: now,
          reason: 'Demande de remboursement',
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Durant'), findsOneWidget);

    await tester.tap(find.text(Strings.whatsapp));
    await _settle(tester);

    expect(find.text('Bob Durant'), findsOneWidget);
    expect(find.text('Alice Martin'), findsNothing);
  });

  testWidgets('Inbox search filters by customer name', (tester) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        _conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          at: now,
        ),
        _conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          at: now,
          reason: 'Demande de remboursement',
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'Alice');
    await _settle(tester);

    expect(find.text('Alice Martin'), findsOneWidget);
    expect(find.text('Bob Durant'), findsNothing);
  });

  testWidgets('Inbox separates human and bot conversations', (tester) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        _conversation(
          senderId: '1000000000001',
          platform: 'facebook',
          name: 'Alice Martin',
          at: now,
        ),
        _conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          at: now,
          mode: ChatMode.bot,
          status: 'active',
          reason: '',
        ),
      ],
    );

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    expect(find.text('${Strings.humanSection} (1)'), findsOneWidget);
    expect(find.text('${Strings.botSection} (1)'), findsOneWidget);
  });

  testWidgets('Inbox take-over switches a bot conversation to human', (
    tester,
  ) async {
    final api = _MockCmApi();
    final now = DateTime.now();
    when(api.conversations).thenAnswer(
      (_) async => [
        _conversation(
          senderId: '21650123456',
          platform: 'whatsapp',
          name: 'Bob Durant',
          at: now,
          mode: ChatMode.bot,
          status: 'active',
          reason: '',
        ),
      ],
    );
    when(() => api.setAiMode('21650123456', 'whatsapp', ChatMode.human))
        .thenAnswer((_) async => ChatMode.human);

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    expect(find.text(Strings.botHandler), findsNWidgets(2));

    await tester.tap(find.byTooltip(Strings.takeOver));
    await _settle(tester);

    verify(() => api.setAiMode('21650123456', 'whatsapp', ChatMode.human))
        .called(1);
    expect(find.text(Strings.botHandler), findsOneWidget);
    expect(find.text(Strings.humanHandler), findsNWidgets(2));
    expect(find.text('${Strings.humanSection} (1)'), findsOneWidget);
  });

  testWidgets('Inbox shows the empty state', (tester) async {
    final api = _MockCmApi();
    when(api.conversations).thenAnswer((_) async => []);

    final cubit = InboxCubit(api, onUnauthorized: () {});
    await cubit.load();

    await tester.pumpWidget(_testWidget(cubit));
    await _settle(tester);

    expect(find.text(Strings.noConversations), findsOneWidget);
    expect(find.text(Strings.noConversationsBody), findsOneWidget);
  });
}
