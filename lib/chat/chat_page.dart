import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    final busy = context.select<ChatCubit, bool>(
      (c) => c.state.sending || c.state.switching,
    );
    final switching = context.select<ChatCubit, bool>((c) => c.state.switching);
    final resolvedName = chat?.customerName;
    return AppBar(
      // Opened from a push alert there is nothing to pop: go to the list.
      leading: IconButton(
        tooltip: Strings.back,
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/inbox'),
      ),
      title: Text(
        chat == null
            ? Strings.chatTitle
            : Strings.customerLabel(
                resolvedName,
                chat!.senderId,
                platform: chat!.platform,
              ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: _nameDirection(resolvedName ?? chat?.customerName),
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      actions: [
        if (chat != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChannelChip(chat!.platform),
          ),
          IconButton(
            tooltip: chat!.mode == ChatMode.human
                ? Strings.activateBot
                : Strings.takeOver,
            icon: switching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    chat!.mode == ChatMode.human
                        ? Icons.smart_toy_outlined
                        : Icons.person_outline,
                  ),
            onPressed: busy
                ? null
                : () {
                    if (chat!.mode == ChatMode.human) {
                      _confirmGiveBack(context);
                    } else {
                      context.read<ChatCubit>().setAiMode(ChatMode.human);
                    }
                  },
          ),
          const SizedBox(width: AppSpacing.xs),
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
        if (chat.reason.trim().isNotEmpty)
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
          BlocListener<ChatCubit, ChatState>(
            // A send succeeded: the cubit cleared the draft, so clear the field.
            listenWhen: (previous, current) =>
                previous.draft.isNotEmpty && current.draft.isEmpty,
            listener: (_, __) => _reply.clear(),
            child: _Composer(controller: _reply),
          )
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
            itemBuilder: (context, i) => _BubbleEntry(
              message: messages[i],
              previous: i > 0 ? messages[i - 1] : null,
              next: i < messages.length - 1 ? messages[i + 1] : null,
            ),
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

/// Removes what must never reach the screen from a bot message: the
/// `[[ESCALATE]]` token and prompt memory (`{"history": [...]}`) that leaked
/// into the text. Falls back to the original when nothing readable is left.
String cleanMessageText(String text) {
  var cleaned = text.replaceAll('[[ESCALATE]]', '');
  final leak = cleaned.indexOf(RegExp(r'\{\s*"history"'));
  if (leak >= 0) cleaned = cleaned.substring(0, leak);
  cleaned = cleaned.trim();
  return cleaned.isEmpty ? text : cleaned;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime day, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final diff = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(day.year, day.month, day.day)).inDays;
  if (diff == 0) return Strings.today;
  if (diff == 1) return Strings.yesterday;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(day.day)}/${two(day.month)}/${day.year}';
}

class _BubbleEntry extends StatelessWidget {
  const _BubbleEntry({required this.message, this.previous, this.next});

  final ChatMessage message;
  final ChatMessage? previous;
  final ChatMessage? next;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.role == 'customer';
    final chat = context.select<ChatCubit, Chat?>((c) => c.state.chat);
    final isBot = !isCustomer && chat?.mode == ChatMode.bot;
    final isCm = !isCustomer && chat?.mode == ChatMode.human;

    final at = message.at?.toLocal();
    final previousAt = previous?.at?.toLocal();
    final newDay =
        at != null && (previousAt == null || !_sameDay(at, previousAt));
    final groupedWithPrevious =
        previous != null &&
        !newDay &&
        (previous!.role == 'customer') == isCustomer;
    final lastOfGroup =
        next == null ||
        (next!.role == 'customer') != isCustomer ||
        (at != null && next!.at != null && !_sameDay(at, next!.at!.toLocal()));

    return Column(
      children: [
        if (newDay) _DayChip(label: _dayLabel(at!)),
        Padding(
          padding: EdgeInsets.only(
            top: groupedWithPrevious ? 2 : AppSpacing.vertical12,
          ),
          child: _Bubble(
            message: message,
            isCustomer: isCustomer,
            isBot: isBot,
            isCm: isCm,
            lastOfGroup: lastOfGroup,
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: context.theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
    required this.lastOfGroup,
  });

  final ChatMessage message;
  final bool isCustomer;
  final bool isBot;
  final bool isCm;

  /// Only the last bubble of a run shows the sender label, the time and the
  /// speech-bubble corner.
  final bool lastOfGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final text = isCustomer ? message.text : cleanMessageText(message.text);
    final direction = _detectDirection(text);
    final at = message.at?.toLocal();
    final time = at == null
        ? null
        : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

    final Color foreground;
    final Color? solid;
    Gradient? gradient;
    if (isCustomer) {
      solid = scheme.surfaceContainer;
      foreground = scheme.onSurface;
    } else if (isBot) {
      solid = scheme.surfaceContainerHigh;
      foreground = scheme.onSurfaceVariant;
    } else {
      solid = null;
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary,
          Color.lerp(scheme.primary, AppColors.deepTeal, 0.35)!,
        ],
      );
      foreground = scheme.onPrimary;
    }

    // Speech-bubble corner on the sender's side, last bubble of a run only.
    const big = Radius.circular(20);
    const tail = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: isCustomer && lastOfGroup ? tail : big,
      bottomRight: !isCustomer && lastOfGroup ? tail : big,
    );

    return Align(
      alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
      child: Semantics(
        container: true,
        label: text,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: solid,
              gradient: gradient,
              borderRadius: radius,
              border: isCustomer
                  ? Border.all(color: scheme.outlineVariant, width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: direction,
                    child: SelectableText(
                      text,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        height: 1.5,
                      ),
                      showCursor: false,
                    ),
                  ),
                  if (lastOfGroup && (isBot || time != null))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isBot) ...[
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 13,
                              color: foreground.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                Strings.bot,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: foreground.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (time != null)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                          if (time != null)
                            Text(
                              time,
                              textDirection: TextDirection.ltr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: foreground.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                          if (isCm) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: foreground.withValues(alpha: 0.85),
                            ),
                          ],
                        ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickReplies(controller: widget.controller),
        _buildBar(context),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
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
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Icon(Icons.send, color: scheme.onPrimary, size: 20),
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
    final switching = context.select<ChatCubit, bool>((c) => c.state.switching);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
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
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: switching
                ? null
                : () => context.read<ChatCubit>().setAiMode(ChatMode.human),
            icon: switching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_outline, size: 18),
            label: const Text(Strings.takeOver),
          ),
        ],
      ),
    );
  }
}

/// Canned replies: a tap fills the composer. Shown while it is empty.
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: value.text.isNotEmpty
            ? const SizedBox(width: double.infinity)
            : Semantics(
                label: Strings.quickRepliesLabel,
                container: true,
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageGutter,
                    ),
                    itemCount: Strings.quickReplies.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) => ActionChip(
                      label: Text(Strings.quickReplies[i]),
                      onPressed: () {
                        controller.value = TextEditingValue(
                          text: Strings.quickReplies[i],
                          selection: TextSelection.collapsed(
                            offset: Strings.quickReplies[i].length,
                          ),
                        );
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
