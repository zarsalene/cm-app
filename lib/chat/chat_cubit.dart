import 'package:bloc/bloc.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/strings.dart';
import 'package:equatable/equatable.dart';

/// `chat` is null until the first load succeeds. `draft` is the reply text
/// that was sent or is being sent: it stays until the send succeeds.
final class const ChatState({
  final Chat? chat,
  final bool sending = false,
  final String? error,
  final String draft = '',
}) extends Equatable {
  /// Every call sets `error` again: a plain copy clears it.
  ChatState copyWith({
    Chat? chat,
    bool? sending,
    String? error,
    String? draft,
  }) => ChatState(
    chat: chat ?? this.chat,
    sending: sending ?? this.sending,
    error: error,
    draft: draft ?? this.draft,
  );

  @override
  List<Object?> get props => [chat, sending, error, draft];
}

class ChatCubit extends Cubit<ChatState> {
  new(
    this._api,
    this._senderId,
    this._platform, {
    required this._onUnauthorized,
  }) : super(const ChatState());

  final CmApi _api;
  final String _senderId;
  final String _platform;
  final void Function() _onUnauthorized;

  Future<void> load() async {
    emit(state.copyWith());
    try {
      final chat = await _api.chat(_senderId, _platform);
      if (!isClosed) emit(state.copyWith(chat: chat));
    } on Object catch (e) {
      // A failed refresh must not end a send that is still in flight.
      _fail(e, endsSending: false);
    }
  }

  /// Sends [text]. On failure the text stays in `draft`.
  Future<void> sendReply(String text) async {
    final chat = state.chat;
    if (state.sending || chat == null || chat.mode == ChatMode.bot) return;
    if (text.trim().isEmpty) return;
    emit(state.copyWith(sending: true, draft: text));
    try {
      await _api.reply(_senderId, _platform, text);
      if (isClosed) return;
      final message = ChatMessage(role: 'bot', text: text, at: DateTime.now());
      // Current chat, not the one before the await: a refresh may have landed.
      final current = state.chat ?? chat;
      emit(
        state.copyWith(
          sending: false,
          draft: '',
          chat: _chatWith(current, messages: [...current.messages, message]),
        ),
      );
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> giveBack() async {
    final chat = state.chat;
    if (state.sending || chat == null) return;
    emit(state.copyWith(sending: true));
    try {
      await _api.giveBack(_senderId, _platform);
      if (isClosed) return;
      final current = state.chat ?? chat;
      emit(
        state.copyWith(
          sending: false,
          chat: _chatWith(current, mode: ChatMode.bot),
        ),
      );
    } on Object catch (e) {
      _fail(e);
    }
  }

  void _fail(Object error, {bool endsSending = true}) {
    final expired = error is UnauthorizedException;
    if (expired) _onUnauthorized();
    if (isClosed) return;
    emit(
      state.copyWith(
        sending: !(endsSending || expired) && state.sending,
        error: expired ? null : Strings.errorFor(error),
      ),
    );
  }

  static Chat _chatWith(
    Chat chat, {
    ChatMode? mode,
    List<ChatMessage>? messages,
  }) => Chat(
    senderId: chat.senderId,
    platform: chat.platform,
    customerName: chat.customerName,
    reason: chat.reason,
    mode: mode ?? chat.mode,
    messages: messages ?? chat.messages,
  );
}
