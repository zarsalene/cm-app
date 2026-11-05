import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/serene_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/chat/chat_cubit.dart';
import 'package:cm_app/chat/chat_strings.dart';
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
    final mode = context.select<ChatCubit, ChatMode?>(
      (c) => c.state.chat?.mode,
    );
    return Scaffold(
      appBar: _ChatAppBar(mode: mode),
      body: SafeArea(
        child: mode == null ? const _Loading() : const _Conversation(),
      ),
    );
  }
}

final _rtlChar = RegExp(r'[֐-׿؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');

/// Right-to-left when [text] has any Arabic or Hebrew letter.
TextDirection _directionOf(String text) =>
    _rtlChar.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.mode});

  final ChatMode? mode;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    return AppBar(
      centerTitle: false,
      scrolledUnderElevation: 0,
      // Opened from a push alert there is nothing to pop: go to the list.
      leading: IconButton(
        tooltip: Strings.back,
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/inbox'),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.chatTitle,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (mode != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: mode == ChatMode.human
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 6),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  mode == ChatMode.human
                      ? ChatStrings.statusActive
                      : ChatStrings.statusBot,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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
  const _Conversation();

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
    // The page builds this only once a chat exists.
    final chat = context.select<ChatCubit, Chat>((c) => c.state.chat!);
    final error = context.select<ChatCubit, String?>((c) => c.state.error);

    return Column(
      children: [
        _CustomerHeader(chat: chat),
        if (chat.reason.trim().isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.25,
            ),
            child: SingleChildScrollView(
              child: Semantics(
                container: true,
                child: _ReasonCard(
                  reason: chat.reason,
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
            child: _InlineNotice(icon: Icons.error_outline, text: error),
          ),
        if (chat.mode == ChatMode.human)
          BlocListener<ChatCubit, ChatState>(
            // A send succeeded: the cubit cleared the draft, so clear the field.
            listenWhen: (previous, current) =>
                previous.draft.isNotEmpty && current.draft.isEmpty,
            listener: (_, __) => _reply.clear(),
            child: _Composer(controller: _reply, platform: chat.platform),
          )
        else
          const Padding(
            padding: EdgeInsets.all(AppSpacing.pageGutter),
            child: _BotActiveCard(),
          ),
      ],
    );
  }
}

/// Who the customer is, on which channel, and the bot / human switch.
class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.chat});

  final Chat chat;

  void _onHandoff(BuildContext context, ChatMode mode) {
    final cubit = context.read<ChatCubit>();
    if (mode == ChatMode.human) {
      unawaited(cubit.setAiMode(ChatMode.human));
      return;
    }
    final hasDraft = cubit.state.draft.trim().isNotEmpty;
    unawaited(
      showDialog<bool>(
        context: context,
        builder: (context) => _GiveBackDialog(hasDraft: hasDraft),
      ).then((ok) {
        if ((ok ?? false) && !cubit.isClosed) unawaited(cubit.giveBack());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final busy = context.select<ChatCubit, bool>(
      (c) => c.state.sending || c.state.switching,
    );
    final name = Strings.customerLabel(
      chat.customerName,
      chat.senderId,
      platform: chat.platform,
    );
    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.md - 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InitialsAvatar(name: name, platform: chat.platform, size: 44),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: _directionOf(chat.customerName ?? ''),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ChatStrings.channelLine(chat.platform, chat.senderId),
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: HandoffSwitch(
                mode: chat.mode,
                busy: busy,
                onChanged: (mode) => _onHandoff(context, mode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.reason,
    required this.expanded,
    required this.onToggle,
  });

  final String reason;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        0,
      ),
      child: ThreadCard(
        stripe: context.amber,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Icon(Icons.flag_outlined, color: context.amber, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.reasonCardLabel,
                      style: text.labelLarge?.copyWith(
                        color: context.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reason,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: onToggle,
              tooltip: expanded ? Strings.collapse : Strings.expand,
              color: scheme.onSurfaceVariant,
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
    unawaited(
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
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
          PositionedDirectional(
            bottom: AppSpacing.vertical12,
            start: 0,
            end: 0,
            child: Center(child: _LatestPill(onTap: _scrollToBottom)),
          ),
      ],
    );
  }
}

/// "Derniers messages" pill with a down arrow.
class _LatestPill extends StatelessWidget {
  const _LatestPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Semantics(
      button: true,
      label: Strings.scrollToLatest,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 4,
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward, size: 18, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    ChatStrings.latestMessages,
                    style: context.theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
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
        if (newDay) _DayChip(label: _dayLabel(at)),
        Padding(
          padding: EdgeInsets.only(
            top: groupedWithPrevious ? 2 : AppSpacing.vertical12,
          ),
          child: _Bubble(
            message: message,
            platform: chat?.platform ?? '',
            isCustomer: isCustomer,
            isBot: isBot,
            isCm: isCm,
            showHeader: !groupedWithPrevious,
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
          borderRadius: BorderRadius.circular(AppRadius.pill),
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
    required this.platform,
    required this.isCustomer,
    required this.isBot,
    required this.isCm,
    required this.showHeader,
    required this.lastOfGroup,
  });

  final ChatMessage message;
  final String platform;
  final bool isCustomer;
  final bool isBot;
  final bool isCm;

  /// First bubble of a run: shows the sender label and the time above it.
  final bool showHeader;

  /// Last bubble of a run: gets the speech-bubble corner.
  final bool lastOfGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final text = isCustomer ? message.text : cleanMessageText(message.text);
    final at = message.at?.toLocal();
    final time = at == null
        ? null
        : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

    final Color background;
    final Color foreground;
    if (isCustomer) {
      background = scheme.surfaceContainerHigh;
      foreground = scheme.onSurface;
    } else if (isBot) {
      background = scheme.surfaceContainerLow;
      foreground = scheme.onSurfaceVariant;
    } else {
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    }

    // Speech-bubble corner on the sender's side, last bubble of a run only.
    const big = Radius.circular(AppRadius.bubble);
    const tail = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: isCustomer && lastOfGroup ? tail : big,
      bottomRight: !isCustomer && lastOfGroup ? tail : big,
    );

    final (label, labelColor, labelIcon) = isCustomer
        ? (ChatStrings.customerSender(platform), scheme.onSurfaceVariant, null)
        : isBot
        ? (ChatStrings.assistantBot, scheme.primary, Icons.smart_toy_outlined)
        : (ChatStrings.you, scheme.primary, null);

    return Align(
      alignment: isCustomer
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: isCustomer
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.xs,
                  left: AppSpacing.xs,
                  right: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (labelIcon != null) ...[
                      Icon(labelIcon, size: 14, color: labelColor),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (time != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        time,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (isCm) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            Semantics(
              container: true,
              label: text,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: radius,
                  border: isBot
                      ? Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Directionality(
                    textDirection: _directionOf(text),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller, required this.platform});

  final TextEditingController controller;
  final String platform;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  TextDirection _direction = TextDirection.ltr;

  void _onChanged(String value) {
    final direction = _directionOf(value);
    if (direction != _direction) {
      setState(() => _direction = direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final sending = context.select<ChatCubit, bool>((c) => c.state.sending);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuickReplies(controller: widget.controller),
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              end: AppSpacing.xs,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
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
                    decoration: const InputDecoration(
                      hintText: Strings.replyHint,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md - 4,
                        vertical: AppSpacing.md - 2,
                      ),
                    ),
                    onChanged: _onChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ValueListenableBuilder(
                  valueListenable: widget.controller,
                  builder: (context, value, _) => IconButton.filled(
                    tooltip: Strings.send,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                    ),
                    onPressed: sending || value.text.trim().isEmpty
                        ? null
                        : () {
                            unawaited(
                              context.read<ChatCubit>().sendReply(value.text),
                            );
                            unawaited(HapticFeedback.lightImpact());
                          },
                    icon: sending
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimaryContainer,
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 6),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                ChatStrings.sendVia(widget.platform),
                style: context.theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GiveBackDialog extends StatelessWidget {
  const _GiveBackDialog({required this.hasDraft});

  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 56,
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 28,
                  color: scheme.onPrimaryContainer,
                ),
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

/// Shown instead of the composer while the bot answers.
class _BotActiveCard extends StatelessWidget {
  const _BotActiveCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final switching = context.select<ChatCubit, bool>((c) => c.state.switching);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: scheme.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    Strings.botAnswersAgain,
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: switching
                  ? null
                  : () => unawaited(
                      context.read<ChatCubit>().setAiMode(ChatMode.human),
                    ),
              icon: switching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_outline, size: 18),
              label: const Text(Strings.takeOver),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canned replies ("Macros"): a tap fills the composer. Shown while it is
/// empty.
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: value.text.isNotEmpty
            ? const SizedBox(width: double.infinity)
            : Semantics(
                label: Strings.quickRepliesLabel,
                container: true,
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageGutter,
                    ),
                    itemCount: Strings.quickReplies.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Row(
                          children: [
                            Icon(Icons.bolt, size: 18, color: context.amber),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${ChatStrings.macros} :',
                              style: context.theme.textTheme.labelLarge
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        );
                      }
                      final reply = Strings.quickReplies[i - 1];
                      return ActionChip(
                        // Capped: a long macro must not push the chip off screen.
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            reply,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () {
                          controller.value = TextEditingValue(
                            text: reply,
                            selection: TextSelection.collapsed(
                              offset: reply.length,
                            ),
                          );
                          unawaited(HapticFeedback.selectionClick());
                        },
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
