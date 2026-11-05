import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/inbox/inbox_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCmApi extends Mock implements CmApi {}

const _bot = Conversation(
  senderId: '21650123456',
  platform: 'whatsapp',
  customerName: 'Mohamed Trabelsi',
  lastMessage: 'Bonjour',
  mode: ChatMode.bot,
  status: 'active',
);

const _human = Conversation(
  senderId: '1000000000001',
  platform: 'facebook',
  customerName: 'Sana Ben Ali',
  lastMessage: 'Je veux un humain',
  mode: ChatMode.human,
  status: 'open',
  reason: 'Demande un humain',
);

void main() {
  late CmApi api;
  late StreamController<void> ticks;

  setUp(() => api = _MockCmApi());

  InboxCubit build({void Function()? onUnauthorized}) =>
      InboxCubit(api, onUnauthorized: onUnauthorized ?? () {});

  group('InboxCubit', () {
    blocTest<InboxCubit, InboxState>(
      'load publishes the conversations',
      setUp: () =>
          when(api.conversations).thenAnswer((_) async => [_human, _bot]),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const InboxState(loading: true),
        isA<InboxState>()
            .having((s) => s.loading, 'loading', false)
            .having(
              (s) => s.conversations,
              'conversations',
              orderedEquals([_human, _bot]),
            ),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'setAiMode updates only the target conversation',
      setUp: () =>
          when(() => api.setAiMode('21650123456', 'whatsapp', ChatMode.human))
              .thenAnswer((_) async => ChatMode.human),
      build: build,
      seed: () => const InboxState(conversations: [_human, _bot]),
      act: (cubit) => cubit.setAiMode(_bot, ChatMode.human),
      expect: () => [
        isA<InboxState>().having((s) => s.toggling, 'toggling', {
          'whatsapp/21650123456',
        }),
        isA<InboxState>()
            .having((s) => s.toggling, 'toggling', isEmpty)
            .having(
              (s) => s.conversations.last.mode,
              'target mode',
              ChatMode.human,
            )
            .having((s) => s.conversations.last.status, 'target status', 'open')
            .having(
              (s) => s.conversations.first.mode,
              'other mode',
              ChatMode.human,
            ),
      ],
    );

    blocTest<InboxCubit, InboxState>(
      'setAiMode failure clears toggling and shows an error',
      setUp: () =>
          when(() => api.setAiMode('21650123456', 'whatsapp', ChatMode.human))
              .thenThrow(const SendFailedException('nope')),
      build: build,
      seed: () => const InboxState(conversations: [_human, _bot]),
      act: (cubit) => cubit.setAiMode(_bot, ChatMode.human),
      expect: () => [
        isA<InboxState>().having((s) => s.toggling, 'toggling', {
          'whatsapp/21650123456',
        }),
        isA<InboxState>()
            .having((s) => s.toggling, 'toggling', isEmpty)
            .having((s) => s.error, 'error', 'Envoi impossible'),
      ],
    );

    test('setAiMode unauthorized calls the logout callback', () async {
      var unauthorized = 0;
      when(() => api.setAiMode('21650123456', 'whatsapp', ChatMode.human))
          .thenThrow(const UnauthorizedException());
      final cubit = build(onUnauthorized: () => unauthorized++);
      addTearDown(cubit.close);

      await cubit.setAiMode(_bot, ChatMode.human);

      expect(unauthorized, 1);
      expect(cubit.state.toggling, isEmpty);
      expect(cubit.state.error, isNull);
    });

    blocTest<InboxCubit, InboxState>(
      'polling: a tick refreshes, 2 failures set offline, a success clears it',
      setUp: () {
        ticks = StreamController<void>();
        var calls = 0;
        when(api.conversations).thenAnswer((_) async {
          calls++;
          if (calls <= 2) throw const NetworkException();
          return [_human];
        });
      },
      tearDown: () => ticks.close(),
      build: () =>
          InboxCubit(api, onUnauthorized: () {}, ticks: () => ticks.stream),
      act: (cubit) async {
        cubit.startPolling();
        for (var i = 0; i < 3; i++) {
          ticks.add(null);
          await Future<void>.delayed(Duration.zero);
        }
      },
      expect: () => [
        const InboxState(),
        const InboxState(offline: true),
        const InboxState(conversations: [_human]),
      ],
      verify: (_) => verify(api.conversations).called(3),
    );
  });
}
