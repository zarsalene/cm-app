import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/splash_page.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/view/app.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

class _MockCmApi extends Mock implements CmApi;

class _MockTokenStore extends Mock implements TokenStore;

const _fbId = '1000000000001';

void main() {
  testWidgets(
    'Facebook escalation: splash, login, list, chat, reply, give back',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final api = _MockCmApi();
      final store = _MockTokenStore();
      when(store.readRememberMe).thenAnswer((_) async => false);
      when(
        () => store.write(
          token: any(named: 'token'),
          username: any(named: 'username'),
          rememberMe: any(named: 'rememberMe'),
        ),
      ).thenAnswer((_) async {});
      when(store.delete).thenAnswer((_) async {});
      when(() => api.login('cm', 'secret')).thenAnswer(
        (_) async => Session(
          token: 't',
          username: 'cm',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      when(api.logout).thenAnswer((_) async {});
      var closed = false;
      when(api.escalations).thenAnswer(
        (_) async => [
          Escalation(
            senderId: _fbId,
            platform: 'facebook',
            customerName: 'Sana Ben Ali',
            reason: 'Le client demande un remboursement',
            escalatedAt: DateTime.now().subtract(const Duration(minutes: 4)),
            status: closed ? 'closed' : 'open',
          ),
        ],
      );
      when(() => api.chat(_fbId, 'facebook')).thenAnswer(
        (_) async => Chat(
          senderId: _fbId,
          platform: 'facebook',
          customerName: 'Sana Ben Ali',
          reason: 'Le client demande un remboursement',
          mode: closed ? ChatMode.bot : ChatMode.human,
          messages: const [
            ChatMessage(role: 'customer', text: 'Je veux un remboursement'),
            ChatMessage(role: 'bot', text: 'Je vous mets en relation'),
          ],
        ),
      );
      when(() => api.reply(_fbId, 'facebook', any())).thenAnswer((_) async {});
      when(() => api.giveBack(_fbId, 'facebook')).thenAnswer((_) async {
        closed = true;
      });

      await tester.pumpWidget(App(tokenStore: store, api: api));

      // Splash plays for its full length, then login shows.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Se connecter'), findsNothing);
      await tester.pump(splashDuration);
      await tester.settle();
      expect(find.text('Se connecter'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'cm');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.tap(find.text('Se connecter'));
      await tester.settle();

      // Dashboard -> escalation list.
      await tester.tap(find.text('Voir les 1 ouverte'));
      await tester.settle();
      expect(find.text('Sana Ben Ali'), findsOneWidget);
      expect(find.text('FB'), findsOneWidget);

      // List -> chat.
      await tester.tap(find.text('Sana Ben Ali'));
      await tester.settle();
      expect(find.text('Je veux un remboursement'), findsOneWidget);
      expect(find.text('FB'), findsOneWidget);

      // A quick reply fills the composer.
      final quick = Strings.quickReplies.first;
      await tester.tap(find.text(quick));
      await tester.pump();
      expect(find.widgetWithText(TextField, quick), findsOneWidget);

      // Reply goes to the Facebook thread.
      await tester.enterText(find.byType(TextField).last, 'Bonjour Sana');
      await tester.pump();
      await tester.tap(find.byTooltip('Envoyer'));
      await tester.settle();
      verify(() => api.reply(_fbId, 'facebook', 'Bonjour Sana')).called(1);

      // Give the chat back to the bot.
      await tester.tap(find.byTooltip('Rendre au bot'));
      await tester.settle();
      await tester.tap(find.text('Confirmer'));
      await tester.settle();
      verify(() => api.giveBack(_fbId, 'facebook')).called(1);

      await tester.pumpWidget(const SizedBox());
    },
  );
}
