import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final ChatCubit _cubit = context.read<ChatCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final life = WidgetsBinding.instance.lifecycleState;
    if (life == null || life == AppLifecycleState.resumed) {
      _cubit.startPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cubit.isClosed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_cubit.refresh());
        _cubit.startPolling();
      case AppLifecycleState.paused ||
          AppLifecycleState.hidden ||
          AppLifecycleState.detached:
        _cubit.stopPolling();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.select<ChatCubit, Chat?>((c) => c.state.chat);
    return Scaffold(
      appBar: ChatAppBar(chat: chat),
      body: SafeArea(
        child: chat == null ? const _Loading() : _Conversation(chat: chat),
      ),
    );
  }
}

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({required this.chat, super.key});

  final Chat? chat;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final sending = context.select<ChatCubit, bool>((c) => c.state.sending);
    return AppBar(
      title: Text(
        chat == null
            ? Strings.chatTitle
            : Strings.customerLabel(chat!.customerName, chat!.senderId),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: _nameDirection(chat?.customerName),
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      actions: [
        if (chat != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ChannelChip(chat!.platform),
          ),
          if (chat!.mode == ChatMode.human && !sending)
            IconButton(
              tooltip: Strings.giveBack,
              icon: const Icon(Icons.handshake_outlined),
              onPressed: () => _confirmGiveBack(context),
            ),
        ],
      ],
    );
  }

  TextDirection _nameDirection(String? name) {
    if (name == null || name.isEmpty) return TextDirection.ltr;
    return _detectDirection(name);
  }

  void _confirmGiveBack(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final state = cubit.state;
    final hasDraft = state.draft.trim().isNotEmpty;
    showDialog<bool>(
      context: context,
      builder: (context) => _GiveBackDialog(hasDraft: hasDraft),
    ).then((ok) {
      if ((ok ?? false) && !cubit.isClosed) {
        cubit.giveBack();
      }
    });
  }

  static TextDirection _detectDirection(String text) {
    final rtlRegex = RegExp(
      r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    for (final char in text.characters) {
      if (rtlRegex.hasMatch(char)) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final error = context.select<ChatCubit, String?>((c) => c.state.error);
    if (error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(liveRegion: true, child: Text(error)),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.read<ChatCubit>().load(),
            child: const Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}

class _Conversation extends StatefulWidget {
  const _Conversation({required this.chat});

  final Chat chat;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  late final _reply = TextEditingController(
    text: context.read<ChatCubit>().state.draft,
  );
  bool _reasonExpanded = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final error = context.select<ChatCubit, String?>((c) => c.state.error);

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.25,
          ),
          child: SingleChildScrollView(
            child: Semantics(
              container: true,
              child: _ReasonCard(
                chat: chat,
                expanded: _reasonExpanded,
                onToggle: () =>
                    setState(() => _reasonExpanded = !_reasonExpanded),
              ),
            ),
          ),
        ),
        Expanded(child: _MessageList(messages: chat.messages)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
              vertical: AppSpacing.vertical8,
            ),
            child: _InlineNotice(
              tone: NoticeTone.error,
              icon: Icons.error_outline,
              text: error,
            ),
          ),
        if (chat.mode == ChatMode.human)
          _Composer(controller: _reply)
        else if (chat.mode == ChatMode.bot)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            child: _BotActiveCard(),
          ),
      ],
    );
  }
}

enum NoticeTone { info, warning, error }

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.tone,
    required this.icon,
    required this.text,
  });

  final NoticeTone tone;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final (bg, fg, iconColor) = switch (tone) {
      NoticeTone.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.primary,
      ),
      NoticeTone.warning => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        AppColors.alertAmber,
      ),
      NoticeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        scheme.error,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: context.theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.chat,
    required this.expanded,
    required this.onToggle,
  });

  final Chat chat;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.flag_outlined, color: AppColors.alertAmber, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Strings.reasonCardLabel,
                        style: context.theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    chat.reason,
                    maxLines: expanded ? null : 2,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: onToggle,
              tooltip: expanded ? Strings.collapse : Strings.expand,
              color: scheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({required this.messages});

  final List<ChatMessage> messages;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _controller = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollToNewest();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length && _atBottom) {
      _scrollToNewest();
    }
  }

  bool get _atBottom =>
      !_controller.hasClients ||
      _controller.position.pixels >=
          _controller.position.maxScrollExtent - kMinInteractiveDimension;

  void _onScroll() {
    if (!_atBottom && _controller.hasClients) {
      setState(() => _showScrollToBottom = true);
    } else if (_showScrollToBottom) {
      setState(() => _showScrollToBottom = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients && mounted) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });
  }

  void _scrollToBottom() {
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _showScrollToBottom = false);
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => context.read<ChatCubit>().load(),
          child: ListView.builder(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            itemCount: messages.length,
            itemBuilder: (context, i) =>
                _BubbleEntry(message: messages[i], index: i),
          ),
        ),
        if (_showScrollToBottom)
          Positioned(
            right: AppSpacing.pageGutter,
            bottom: AppSpacing.vertical12,
            child: FloatingActionButton.small(
              onPressed: _scrollToBottom,
              tooltip: Strings.scrollToLatest,
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
      ],
    );
  }
}

class _BubbleEntry extends StatelessWidget {
  const _BubbleEntry({required this.message, required this.index});

  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.role == 'customer';
    final chat = context.select<ChatCubit, Chat?>((c) => c.state.chat);
    final isBot = !isCustomer && chat?.mode == ChatMode.bot;
    final isCm = !isCustomer && chat?.mode == ChatMode.human;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.vertical8),
      child: Column(
        crossAxisAlignment: isCustomer
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          _Bubble(
            message: message,
            isCustomer: isCustomer,
            isBot: isBot,
            isCm: isCm,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isCustomer,
    required this.isBot,
    required this.isCm,
  });

  final ChatMessage message;
  final bool isCustomer;
  final bool isBot;
  final bool isCm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final direction = _detectDirection(message.text);
    final at = message.at?.toLocal();
    final time = at == null
        ? null
        : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

    Color background;
    Color foreground;
    if (isCustomer) {
      background = scheme.surfaceContainer;
      foreground = scheme.onSurface;
    } else if (isBot) {
      background = scheme.surfaceContainerHigh;
      foreground = scheme.onSurfaceVariant;
    } else {
      background = scheme.primary;
      foreground = Colors.white;
    }

    final alignment = isCustomer ? Alignment.centerLeft : Alignment.centerRight;

    return Align(
      alignment: alignment,
      child: Semantics(
        container: true,
        label: message.text,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.bubble)),
              border: isCustomer
                  ? Border.all(color: scheme.outlineVariant, width: 1)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: direction,
                    child: SelectableText(
                      message.text,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        height: 1.6,
                      ),
                      showCursor: false,
                    ),
                  ),
                  if (isBot)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        Strings.bot,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        time,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextDirection _detectDirection(String text) {
    final rtlRegex = RegExp(
      r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    if (text.isEmpty) return TextDirection.ltr;
    for (final char in text.characters) {
      if (rtlRegex.hasMatch(char)) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller});

  final TextEditingController controller;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  TextDirection _direction = TextDirection.ltr;

  void _onChanged(String value) {
    final direction = _detectDirection(value);
    if (direction != _direction) {
      setState(() => _direction = direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final sending = context.select<ChatCubit, bool>((c) => c.state.sending);
    return Container(
      margin: const EdgeInsets.all(AppSpacing.pageGutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: scheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                readOnly: sending,
                textDirection: _direction,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: Strings.replyHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.button),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.button),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.button),
                    ),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ValueListenableBuilder(
              valueListenable: widget.controller,
              builder: (context, value, _) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: Strings.send,
                  onPressed: sending || value.text.trim().isEmpty
                      ? null
                      : () {
                          context.read<ChatCubit>().sendReply(value.text);
                          HapticFeedback.lightImpact();
                        },
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextDirection _detectDirection(String text) {
    final rtlRegex = RegExp(
      r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    if (text.isEmpty) return TextDirection.ltr;
    for (final char in text.characters) {
      if (rtlRegex.hasMatch(char)) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }
}

class _GiveBackDialog extends StatelessWidget {
  const _GiveBackDialog({required this.hasDraft});

  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.dialog)),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.handshake_outlined,
                size: 28,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.vertical16),
            Text(
              Strings.giveBackTitle,
              style: context.theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.vertical12),
            Text(
              hasDraft
                  ? '${Strings.giveBackBody} ${Strings.draftLost}'
                  : Strings.giveBackBody,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.vertical24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(Strings.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(Strings.confirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotActiveCard extends StatelessWidget {
  const _BotActiveCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outlined,
            color: scheme.onPrimaryContainer,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              Strings.botAnswersAgain,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
