import 'dart:async';

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

Stream<void> _every10Seconds() =>
    Stream<void>.periodic(const Duration(seconds: 10));

class ChatCubit extends Cubit<ChatState> {
  /// [_ticks] makes the polling clock (tests pass their own).
  new(
    this._api,
    this._senderId,
    this._platform, {
    required this._onUnauthorized,
    this._ticks = _every10Seconds,
  }) : super(const ChatState());

  final CmApi _api;
  final String _senderId;
  final String _platform;
  final void Function() _onUnauthorized;
  final Stream<void> Function() _ticks;
  StreamSubscription<void>? _poll;
  bool _refreshing = false;

  /// Bumped by every load, send and give-back: a refresh that started
  /// before one of them is dropped, so it cannot undo their result.
  int _seq = 0;

  @override
  Future<void> close() async {
    await _poll?.cancel();
    await super.close();
  }

  /// Refreshes on every tick until [stopPolling]. Call only while resumed.
  void startPolling() {
    if (isClosed) return;
    _poll ??= _ticks().listen((_) => unawaited(refresh()));
  }

  void stopPolling() {
    unawaited(_poll?.cancel());
    _poll = null;
  }

  /// Silent load: no error shown, draft and error kept. Skipped while a
  /// send or give-back runs. Before the first load succeeded it retries
  /// that load instead; its error stays on screen until the retry ends.
  Future<void> refresh() async {
    if (isClosed || _refreshing || state.sending) return;
    _refreshing = true;
    if (state.chat == null) {
      try {
        await load(keepError: true);
      } finally {
        _refreshing = false;
      }
      return;
    }
    final seq = _seq;
    try {
      final chat = await _api.chat(_senderId, _platform);
      if (!isClosed && seq == _seq && !state.sending) {
        emit(state.copyWith(chat: chat, error: state.error));
      }
    } on UnauthorizedException {
      _onUnauthorized();
    } on Object {
      // Silent: the next tick tries again.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> load({bool keepError = false}) async {
    _seq++;
    if (!keepError) emit(state.copyWith());
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
    _seq++;
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
    _seq++;
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
