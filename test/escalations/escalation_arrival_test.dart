import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:cm_app/escalations/escalations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

class _MockCmApi extends Mock implements CmApi;

void main() {
  testWidgets(
    'a Facebook escalation raised by the bot shows up on the next refresh, '
    'and the channel filter hides it for WhatsApp',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final api = _MockCmApi();
      final ticks = StreamController<void>.broadcast();
      var botEscalated = false;
      when(api.escalations).thenAnswer(
        (_) async => [
          if (botEscalated)
            Escalation(
              senderId: '1000000000001',
              platform: 'facebook',
              customerName: 'Sana Ben Ali',
              reason: 'AI decided to escalate (valid end token detected)',
              escalatedAt: DateTime.now(),
              status: 'open',
            ),
        ],
      );
      final cubit = EscalationsCubit(
        api,
        onUnauthorized: () {},
        ticks: () => ticks.stream,
      );

      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const EscalationsPage()),
      );
      unawaited(cubit.load());
      await tester.settle();
      expect(find.text('Aucune escalade'), findsOneWidget);

      // The bot escalates a Messenger conversation; the next poll shows it.
      botEscalated = true;
      ticks.add(null);
      await tester.settle();
      expect(find.text('Sana Ben Ali'), findsOneWidget);
      expect(find.text('FB'), findsOneWidget);
      expect(find.text('Ouvertes (1)'), findsOneWidget);

      await tester.tap(find.text('WhatsApp'));
      await tester.settle();
      expect(find.text('Sana Ben Ali'), findsNothing);
      expect(find.text('Aucun résultat'), findsOneWidget);

      await tester.tap(find.text('Facebook'));
      await tester.settle();
      expect(find.text('Sana Ben Ali'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.settle();
      expect(find.text('Aucun résultat'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      unawaited(cubit.close());
      unawaited(ticks.close());
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
