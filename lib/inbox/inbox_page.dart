import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/motion_widgets.dart';
import 'package:cm_app/app/serene_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/inbox/inbox_cubit.dart';
import 'package:cm_app/inbox/inbox_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Sort order for the inbox.
enum _SortOrder { newestFirst, oldestFirst }

/// Which handler the user wants to see. `waiting` is the open escalations.
enum _ModeFilter { all, waiting, human, bot }

final _rtlChars = RegExp(r'[֐-׿؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');

/// Arabic and Hebrew text reads right-to-left, per message.
TextDirection _directionOf(String text) =>
    _rtlChars.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

/// Minutes a customer has waited for a human, or null when no date is known.
int? _waitMinutes(Conversation c) {
  final since = c.escalatedAt ?? c.lastSeen;
  if (since == null) return null;
  final minutes = DateTime.now().difference(since).inMinutes;
  return minutes < 0 ? 0 : minutes;
}

/// Unified WhatsApp + Facebook inbox.
///
/// Every row is a real conversation from `sales_bot_user_ai_control`; rows
/// that also have an escalation show its reason and status. The bot/human
/// switch writes `sales_bot_user_ai_control` directly, so it works with or
/// without an escalation.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with WidgetsBindingObserver {
  late final InboxCubit _cubit = context.read<InboxCubit>();
  bool _live = true;
  String _query = '';
  String? _channel;
  _ModeFilter _mode = _ModeFilter.all;
  _SortOrder _sort = _SortOrder.newestFirst;
  Timer? _debounce;

  void _toggleLive() {
    setState(() => _live = !_live);
    if (_live) {
      _cubit.startPolling();
      unawaited(_cubit.refresh());
    } else {
      _cubit.stopPolling();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = value.trim().toLowerCase());
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_cubit.checkNotifications());
    final life = WidgetsBinding.instance.lifecycleState;
    if (life == null || life == AppLifecycleState.resumed) {
      _cubit.startPolling();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cubit.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cubit.isClosed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_cubit.checkNotifications());
        unawaited(_cubit.refresh());
        if (_live) _cubit.startPolling();
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
    final notificationsOff = context.select<InboxCubit, bool>(
      (c) => c.state.notificationsOff,
    );
    return Scaffold(
      appBar: BrandAppBar(notificationsOff: notificationsOff),
      bottomNavigationBar: const AppNavBar(current: 1),
      body: Column(
        children: [
          const _NotificationsBanner(),
          const _OfflineNotice(),
          _FilterBar(
            live: _live,
            channel: _channel,
            mode: _mode,
            sortOrder: _sort,
            onToggleLive: _toggleLive,
            onQuery: _onQueryChanged,
            onChannel: (c) => setState(() => _channel = c),
            onMode: (m) => setState(() => _mode = m),
            onSort: (s) => setState(() => _sort = s),
          ),
          Expanded(
            child: _List(
              query: _query,
              channel: _channel,
              mode: _mode,
              sortOrder: _sort,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.live,
    required this.channel,
    required this.mode,
    required this.sortOrder,
    required this.onToggleLive,
    required this.onQuery,
    required this.onChannel,
    required this.onMode,
    required this.onSort,
  });

  final bool live;
  final String? channel;
  final _ModeFilter mode;
  final _SortOrder sortOrder;
  final VoidCallback onToggleLive;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onChannel;
  final ValueChanged<_ModeFilter> onMode;
  final ValueChanged<_SortOrder> onSort;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final conversations = context.select<InboxCubit, List<Conversation>>(
      (c) => c.state.conversations,
    );
    final open = conversations.where((c) => c.status == 'open').length;
    int onChannelCount(String platform) =>
        conversations.where((c) => c.platform == platform).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LiveChip(live: live, onTap: onToggleLive),
              if (open > 0)
                StatusPill(
                  label: InboxStrings.priorityThreads(open),
                  color: context.amber,
                  icon: Icons.bolt,
                ),
              SpinRefreshButton(
                onPressed: () => context.read<InboxCubit>().load(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: Strings.searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: scheme.surfaceContainer,
              border: _pillBorder(Colors.transparent),
              enabledBorder: _pillBorder(
                scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              focusedBorder: _pillBorder(scheme.primary, width: 2),
            ),
          ),
          const SizedBox(height: AppSpacing.vertical12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  InboxStrings.channelLabel,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterPill(
                  label: Strings.allChannels,
                  count: conversations.length,
                  selected: channel == null,
                  onTap: () => onChannel(null),
                ),
                _FilterPill(
                  label: Strings.whatsapp,
                  count: onChannelCount('whatsapp'),
                  dot: AppColors.whatsapp,
                  selected: channel == 'whatsapp',
                  onTap: () => onChannel('whatsapp'),
                ),
                _FilterPill(
                  label: Strings.facebook,
                  count: onChannelCount('facebook'),
                  dot: AppColors.facebook,
                  selected: channel == 'facebook',
                  onTap: () => onChannel('facebook'),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: Strings.allChannels,
                        compact: true,
                        selected: mode == _ModeFilter.all,
                        onTap: () => onMode(_ModeFilter.all),
                      ),
                      _FilterPill(
                        label: InboxStrings.waitingFilter,
                        count: open,
                        dot: context.amber,
                        compact: true,
                        selected: mode == _ModeFilter.waiting,
                        onTap: () => onMode(_ModeFilter.waiting),
                      ),
                      _FilterPill(
                        label: Strings.humanHandler,
                        compact: true,
                        selected: mode == _ModeFilter.human,
                        onTap: () => onMode(_ModeFilter.human),
                      ),
                      _FilterPill(
                        label: Strings.botHandler,
                        compact: true,
                        selected: mode == _ModeFilter.bot,
                        onTap: () => onMode(_ModeFilter.bot),
                      ),
                    ],
                  ),
                ),
              ),
              Tooltip(
                message: InboxStrings.sortTooltip,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSort(
                    sortOrder == _SortOrder.newestFirst
                        ? _SortOrder.oldestFirst
                        : _SortOrder.newestFirst,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sortOrder == _SortOrder.newestFirst
                                ? InboxStrings.sortRecent
                                : InboxStrings.sortOldest,
                            style: text.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.swap_vert,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _pillBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// "Synchro en direct" status chip; a tap pauses or resumes the polling.
class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.live, required this.onTap});

  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Semantics(
      button: true,
      child: Tooltip(
        message: live ? Strings.pauseLive : Strings.resumeLive,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: scheme.surfaceContainer,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md - 4,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (live)
                        LiveDot(color: scheme.primary, size: 6)
                      else
                        Icon(
                          Icons.pause_circle_outline,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        live ? InboxStrings.liveSync : InboxStrings.livePaused,
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
        ),
      ),
    );
  }
}

/// Filter pill: selected = deep-teal tint with a teal border.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.dot,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color? dot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final foreground = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Center(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: selected
                      ? scheme.primaryContainer.withValues(alpha: 0.25)
                      : scheme.surfaceContainer,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.6)
                          : scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? AppSpacing.md - 4 : AppSpacing.md - 2,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dot != null) ...[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 8),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                      ],
                      Text(
                        label,
                        style: (compact ? text.labelMedium : text.labelLarge)
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: AppSpacing.xs + 2),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm - 1,
                              vertical: 1,
                            ),
                            child: Text(
                              '$count',
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Strings.noResults,
            style: context.theme.textTheme.titleMedium?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.query,
    required this.channel,
    required this.mode,
    required this.sortOrder,
  });

  final String query;
  final String? channel;
  final _ModeFilter mode;
  final _SortOrder sortOrder;

  bool _matches(Conversation c) {
    if (channel != null && c.platform != channel) return false;
    if (mode == _ModeFilter.waiting && c.status != 'open') return false;
    if (mode == _ModeFilter.human && c.mode != ChatMode.human) return false;
    if (mode == _ModeFilter.bot && c.mode != ChatMode.bot) return false;
    if (query.isEmpty) return true;
    return [
      c.customerName ?? '',
      c.senderId,
      c.reason,
      c.lastMessage,
    ].any((text) => text.toLowerCase().contains(query));
  }

  List<Conversation> _sortAndFilter(List<Conversation> items) {
    final filtered = items.where(_matches).toList();
    filtered.sort((a, b) {
      switch (sortOrder) {
        case _SortOrder.newestFirst:
          return b.sortAt.compareTo(a.sortAt);
        case _SortOrder.oldestFirst:
          return a.sortAt.compareTo(b.sortAt);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        if (state.conversations.isEmpty && state.loading) {
          return const _SkeletonList();
        }
        final items = _sortAndFilter(state.conversations);
        final open = items.where((i) => i.status == 'open').toList();
        final active = items.where((i) => i.status == 'active').toList();
        final closed = items.where((i) => i.status == 'closed').toList();
        final noneWaiting =
            state.conversations.isNotEmpty &&
            !state.conversations.any((c) => c.status == 'open');

        return RefreshIndicator(
          onRefresh: () => context.read<InboxCubit>().load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (state.error case final error?) _ErrorBanner(error: error),
              if (state.conversations.isEmpty && state.error == null)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.pageGutter),
                  child: _EmptyState(),
                ),
              if (state.conversations.isNotEmpty && items.isEmpty)
                const _NoResults(),
              if (open.isNotEmpty) ...[
                _SectionHeader(
                  title: Strings.humanSection,
                  count: open.length,
                  color: context.amber,
                ),
                for (final item in open) _ConversationRow(item: item),
              ],
              if (active.isNotEmpty) ...[
                _SectionHeader(
                  title: Strings.botSection,
                  count: active.length,
                  color: context.scheme.primary,
                ),
                for (final item in active) _ConversationRow(item: item),
              ],
              if (closed.isNotEmpty) ...[
                _SectionHeader(
                  title: Strings.closedConversations,
                  count: closed.length,
                  color: context.scheme.onSurfaceVariant,
                ),
                for (final item in closed) _ConversationRow(item: item),
              ],
              if (noneWaiting)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.vertical24),
                  child: Text(
                    InboxStrings.allAssigned,
                    textAlign: TextAlign.center,
                    style: context.theme.textTheme.labelLarge?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.vertical16,
        AppSpacing.pageGutter,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$title ($count)',
            style: context.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatefulWidget {
  const _ConversationRow({required this.item});

  final Conversation item;

  @override
  State<_ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<_ConversationRow> {
  bool _pushing = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final name = Strings.customerLabel(
      item.customerName,
      item.senderId,
      platform: item.platform,
    );
    final isOpen = item.status == 'open';
    final isBot = item.status == 'active';
    final human = item.mode == ChatMode.human;
    final toggling = context.select<InboxCubit, bool>(
      (c) => c.state.toggling.contains(_key(item)),
    );
    final preview = item.lastMessage.trim().isNotEmpty
        ? item.lastMessage.trim()
        : (item.reason.trim().isNotEmpty
              ? item.reason.trim()
              : Strings.noRecentMessage);
    final reason = item.reason.trim();
    final hasTime = item.lastSeen != null || item.escalatedAt != null;
    final minutes = _waitMinutes(item);
    final urgent =
        minutes != null && waitSeverity(minutes) == WaitSeverity.urgent;

    final Widget pill = isOpen && minutes != null
        ? WaitPill(minutes: minutes)
        : switch (item.status) {
            'open' => StatusPill(
              label: Strings.humanHandler,
              color: context.amber,
              icon: Icons.person_outline,
            ),
            'active' => StatusPill(
              label: Strings.botSection,
              color: scheme.primary,
              icon: Icons.smart_toy_outlined,
            ),
            _ => StatusPill(
              label: InboxStrings.closedPill,
              color: scheme.onSurfaceVariant,
              icon: Icons.check_circle_outline,
            ),
          };
    final summary =
        '$name, ${item.platform == 'whatsapp' ? Strings.whatsapp : Strings.facebook}, '
        '$preview, ${isOpen ? (minutes == null ? Strings.humanHandler : Strings.waiting(minutes)) : (isBot ? Strings.botSection : Strings.closed)}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs + 2,
      ),
      child: Semantics(
        container: true,
        button: true,
        label: summary,
        onTap: () => _open(context),
        child: ThreadCard(
          stripe: isOpen
              ? (urgent ? context.urgent : context.amber)
              : (isBot ? scheme.outline : null),
          onTap: () => _open(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InitialsAvatar(
                          name: name,
                          platform: item.platform,
                          size: 52,
                        ),
                        const SizedBox(width: AppSpacing.md - 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (hasTime)
                                Text(
                                  Strings.relativeTime(item.sortAt),
                                  style: text.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: pill,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.vertical12),
                    Text(
                      '« $preview »',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: _directionOf(preview),
                      style: text.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (reason.isNotEmpty && reason != preview) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${Strings.reasonPrefix}$reason',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: _directionOf(reason),
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: toggling
                    ? const SizedBox.square(
                        dimension: 48,
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: human
                            ? [
                                Tooltip(
                                  message: Strings.activateBot,
                                  child: FilledButton.icon(
                                    style: _action(
                                      background:
                                          scheme.surfaceContainerHighest,
                                      foreground: scheme.onSurface,
                                    ),
                                    onPressed: () => _confirmGiveBack(context),
                                    icon: const Icon(
                                      Icons.smart_toy_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(Strings.giveBack),
                                  ),
                                ),
                              ]
                            : [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    foregroundColor: scheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _open(context),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(InboxStrings.watch),
                                ),
                                Tooltip(
                                  message: Strings.takeOver,
                                  child: FilledButton.icon(
                                    style: _action(),
                                    onPressed: () => _takeOver(context),
                                    icon: const Icon(
                                      Icons.touch_app_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(Strings.takeOver),
                                  ),
                                ),
                              ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The theme's FilledButton is full width: a row of buttons needs 0.
  static ButtonStyle _action({Color? background, Color? foreground}) =>
      FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        backgroundColor: background,
        foregroundColor: foreground,
      );

  Future<void> _open(BuildContext context) async {
    if (_pushing) return;
    _pushing = true;
    final cubit = context.read<InboxCubit>();
    final sender = Uri.encodeComponent(widget.item.senderId);
    try {
      await context.push('/chat/${widget.item.platform}/$sender');
    } finally {
      _pushing = false;
    }
    if (cubit.isClosed) return;
    await cubit.load();
  }

  void _takeOver(BuildContext context) {
    unawaited(
      context.read<InboxCubit>().setAiMode(widget.item, ChatMode.human),
    );
  }

  Future<void> _confirmGiveBack(BuildContext context) async {
    final cubit = context.read<InboxCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.giveBackTitle),
        content: const Text(Strings.giveBackBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Strings.confirm),
          ),
        ],
      ),
    );
    if (ok == true && !cubit.isClosed) {
      await cubit.setAiMode(widget.item, ChatMode.bot);
    }
  }

  static String _key(Conversation c) => '${c.platform}/${c.senderId}';
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, i) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.forum_outlined, size: 40, color: scheme.primary),
        ),
        const SizedBox(height: AppSpacing.vertical16),
        Text(
          Strings.noConversations,
          style: context.theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          Strings.noConversationsBody,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NotificationsBanner extends StatelessWidget {
  const _NotificationsBanner();

  @override
  Widget build(BuildContext context) {
    final off = context.select<InboxCubit, bool>(
      (c) => c.state.notificationsOff,
    );
    if (!off) return const SizedBox.shrink();
    final amber = context.amber;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs,
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md - 4),
          decoration: BoxDecoration(
            color: amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
            border: Border.all(color: amber.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_off_rounded, color: amber),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  Strings.notificationsOff,
                  style: context.theme.textTheme.bodyLarge?.copyWith(
                    color: amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final offline = context.select<InboxCubit, bool>((c) => c.state.offline);
    if (!offline) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs,
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 4,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: context.scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            border: Border.all(
              color: context.scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: context.scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                Strings.connectionLost,
                style: context.theme.textTheme.labelMedium?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.scheme.error,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.read<InboxCubit>().load(),
            child: const Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}
