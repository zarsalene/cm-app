import 'package:bloc_test/bloc_test.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCmApi extends Mock implements CmApi {}

const _chat = Chat(
  senderId: '1234',
  platform: 'facebook',
  customerName: 'Sami',
  reason: 'Demande un humain',
  mode: ChatMode.human,
  messages: [ChatMessage(role: 'customer', text: 'Salut')],
);

const _botChat = Chat(
  senderId: '1234',
  platform: 'facebook',
  customerName: 'Sami',
  reason: '',
  mode: ChatMode.bot,
  messages: [ChatMessage(role: 'customer', text: 'Salut')],
);

void main() {
  late CmApi api;

  setUp(() => api = _MockCmApi());

  ChatCubit build() =>
      ChatCubit(api, '1234', 'facebook', onUnauthorized: () {});

  group('ChatCubit', () {
    blocTest<ChatCubit, ChatState>(
      'T6 sendReply success appends a bot message and clears the draft',
      setUp: () =>
          when(() => api.reply('1234', 'facebook', 'Bonjour'))
              .thenAnswer((_) async {}),
      build: build,
      seed: () => const ChatState(chat: _chat),
      act: (cubit) => cubit.sendReply('Bonjour'),
      expect: () => [
        isA<ChatState>().having((s) => s.sending, 'sending', true),
        isA<ChatState>()
            .having((s) => s.sending, 'sending', false)
            .having((s) => s.draft, 'draft', '')
            .having((s) => s.chat!.messages.last.role, 'role', 'bot')
            .having((s) => s.chat!.messages.last.text, 'text', 'Bonjour'),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'T7 sendReply SendFailedException sets the error and keeps the draft',
      setUp: () =>
          when(() => api.reply('1234', 'facebook', 'Bonjour'))
              .thenThrow(const SendFailedException('nope')),
      build: build,
      seed: () => const ChatState(chat: _chat),
      act: (cubit) => cubit.sendReply('Bonjour'),
      expect: () => [
        isA<ChatState>().having((s) => s.sending, 'sending', true),
        isA<ChatState>()
            .having((s) => s.error, 'error', 'Envoi impossible')
            .having((s) => s.draft, 'draft', 'Bonjour')
            .having((s) => s.chat!.messages.length, 'messages', 1),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'T8 giveBack switches the mode to bot and clears the draft',
      setUp: () =>
          when(() => api.setAiMode('1234', 'facebook', ChatMode.bot))
              .thenAnswer((_) async => ChatMode.bot),
      build: build,
      seed: () => const ChatState(chat: _chat, draft: 'brouillon'),
      act: (cubit) => cubit.giveBack(),
      expect: () => [
        isA<ChatState>().having((s) => s.switching, 'switching', true),
        isA<ChatState>()
            .having((s) => s.switching, 'switching', false)
            .having((s) => s.chat!.mode, 'mode', ChatMode.bot)
            .having((s) => s.draft, 'draft', ''),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'T8b setAiMode human works without an escalation',
      setUp: () =>
          when(() => api.setAiMode('1234', 'facebook', ChatMode.human))
              .thenAnswer((_) async => ChatMode.human),
      build: build,
      seed: () => const ChatState(chat: _botChat),
      act: (cubit) => cubit.setAiMode(ChatMode.human),
      expect: () => [
        isA<ChatState>().having((s) => s.switching, 'switching', true),
        isA<ChatState>()
            .having((s) => s.switching, 'switching', false)
            .having((s) => s.chat!.mode, 'mode', ChatMode.human),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'T8c setAiMode failure keeps the current mode and shows an error',
      setUp: () =>
          when(() => api.setAiMode('1234', 'facebook', ChatMode.human))
              .thenThrow(const SendFailedException('nope')),
      build: build,
      seed: () => const ChatState(chat: _botChat),
      act: (cubit) => cubit.setAiMode(ChatMode.human),
      expect: () => [
        isA<ChatState>().having((s) => s.switching, 'switching', true),
        isA<ChatState>()
            .having((s) => s.switching, 'switching', false)
            .having((s) => s.chat!.mode, 'mode', ChatMode.bot)
            .having((s) => s.error, 'error', 'Envoi impossible'),
      ],
    );
  });
}
