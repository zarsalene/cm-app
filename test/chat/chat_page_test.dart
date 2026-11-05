import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:cm_app/chat/chat_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

class _MockCmApi extends Mock implements CmApi;

Chat _chat(String? name) => Chat(
  senderId: '9991234',
  platform: 'whatsapp',
  customerName: name,
  reason: 'Réclamation livraison',
  mode: ChatMode.human,
  messages: const [ChatMessage(role: 'customer', text: 'Où est ma commande ?')],
);

void main() {
  testWidgets('T9 ChatPage shows name, reason, channel and the name fallback', (
    tester,
  ) async {
    final api = _MockCmApi();

    Future<void> pumpChat(String? name) async {
      when(() => api.chat('9991234', 'whatsapp'))
          .thenAnswer((_) async => _chat(name));
      await tester.pumpApp(
        BlocProvider(
          key: ValueKey(name),
          create: (_) {
            final cubit = ChatCubit(
              api,
              '9991234',
              'whatsapp',
              onUnauthorized: () {},
            );
            unawaited(cubit.load());
            return cubit;
          },
          child: const ChatPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpChat('Leila');
    expect(find.text('Leila'), findsOneWidget);
    expect(find.textContaining('Réclamation livraison'), findsOneWidget);
    expect(find.text('WA'), findsOneWidget);

    await pumpChat('');
    expect(find.text('Client WhatsApp …1234'), findsOneWidget);
  });

  testWidgets('T10 ChatPage shows Facebook customer name prominently', (
    tester,
  ) async {
    final api = _MockCmApi();
    when(() => api.chat('1000000000001', 'facebook')).thenAnswer(
      (_) async => Chat(
        senderId: '1000000000001',
        platform: 'facebook',
        customerName: 'Sana Ben Ali',
        reason: 'AI decided to escalate',
        mode: ChatMode.human,
        messages: const [ChatMessage(role: 'customer', text: 'Bonjour')],
      ),
    );

    await tester.pumpApp(
      BlocProvider(
        create: (_) {
          final cubit = ChatCubit(
            api,
            '1000000000001',
            'facebook',
            onUnauthorized: () {},
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const ChatPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Facebook customer name should be visible in the header.
    expect(find.text('Sana Ben Ali'), findsOneWidget);
    // Facebook channel badge should be visible.
    expect(find.text('FB'), findsOneWidget);
  });

  testWidgets('T11 ChatPage Facebook fallback includes platform name', (
    tester,
  ) async {
    final api = _MockCmApi();
    when(() => api.chat('1000000000001', 'facebook')).thenAnswer(
      (_) async => Chat(
        senderId: '1000000000001',
        platform: 'facebook',
        customerName: null,
        reason: 'AI decided to escalate',
        mode: ChatMode.human,
        messages: const [],
      ),
    );

    await tester.pumpApp(
      BlocProvider(
        create: (_) {
          final cubit = ChatCubit(
            api,
            '1000000000001',
            'facebook',
            onUnauthorized: () {},
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const ChatPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Fallback should include platform name when no customer name.
    expect(find.text('Client Facebook …0001'), findsOneWidget);
  });
}
