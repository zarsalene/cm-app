import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/motion_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/inbox/inbox_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Sort order for the inbox.
enum _SortOrder { newestFirst, oldestFirst }

/// Which handler the user wants to see.
enum _ModeFilter { all, human, bot }

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

class _InboxPageState extends State<InboxPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final InboxCubit _cubit = context.read<InboxCubit>();
  late final AnimationController _liveIcon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _live = true;
  String _query = '';
  String? _channel;
  _ModeFilter _mode = _ModeFilter.all;
  _SortOrder _sort = _SortOrder.newestFirst;
  Timer? _debounce;

  void _toggleLive() {
    setState(() => _live = !_live);
    if (_live) {
      unawaited(_liveIcon.reverse());
      _cubit.startPolling();
      unawaited(_cubit.refresh());
    } else {
      unawaited(_liveIcon.forward());
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
    _liveIcon.dispose();
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: Strings.backToMenu,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                Strings.inboxTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_live) ...[
              const SizedBox(width: AppSpacing.xs),
              LiveDot(color: context.scheme.primary),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: Strings.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InboxCubit>().load(),
          ),
          IconButton(
            tooltip: _live ? Strings.pauseLive : Strings.resumeLive,
            icon: AnimatedIcon(
              icon: AnimatedIcons.pause_play,
              progress: _liveIcon,
            ),
            onPressed: _toggleLive,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _NotificationsBanner(),
            const _OfflineNotice(),
            _FilterBar(
              channel: _channel,
              mode: _mode,
              sortOrder: _sort,
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
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.channel,
    required this.mode,
    required this.sortOrder,
    required this.onQuery,
    required this.onChannel,
    required this.onMode,
    required this.onSort,
  });

  final String? channel;
  final _ModeFilter mode;
  final _SortOrder sortOrder;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onChannel;
  final ValueChanged<_ModeFilter> onMode;
  final ValueChanged<_SortOrder> onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        0,
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: Strings.searchHint,
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ...[
                  (null, Strings.allChannels),
                  ('facebook', Strings.facebook),
                  ('whatsapp', Strings.whatsapp),
                ].map(
                  (entry) => ChoiceChip(
                    label: Text(entry.$2),
                    selected: channel == entry.$1,
                    onSelected: (_) => onChannel(entry.$1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ...[
                  (_ModeFilter.all, Strings.allConversations),
                  (_ModeFilter.human, Strings.humanHandler),
                  (_ModeFilter.bot, Strings.botHandler),
                ].map(
                  (entry) => ChoiceChip(
                    label: Text(entry.$2),
                    selected: mode == entry.$1,
                    onSelected: (_) => onMode(entry.$1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                const Text(
                  Strings.trier,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                ChoiceChip(
                  label: Text(Strings.sortNewestFirst),
                  selected: sortOrder == _SortOrder.newestFirst,
                  onSelected: (_) => onSort(_SortOrder.newestFirst),
                ),
                ChoiceChip(
                  label: Text(Strings.sortOldestFirst),
                  selected: sortOrder == _SortOrder.oldestFirst,
                  onSelected: (_) => onSort(_SortOrder.oldestFirst),
                ),
              ],
            ),
          ),
        ],
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
                  color: AppColors.alertAmber,
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
        AppSpacing.vertical24,
        AppSpacing.pageGutter,
        AppSpacing.vertical8,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
            ),
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

class _ConversationRowState extends State<_ConversationRow>
    with SingleTickerProviderStateMixin {
  bool _pushing = false;
  late final AnimationController _enterController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = context.scheme;
    final name = Strings.customerLabel(
      item.customerName,
      item.senderId,
      platform: item.platform,
    );
    final hasName = (item.customerName ?? '').trim().isNotEmpty;
    final isOpen = item.status == 'open';
    final isBot = item.status == 'active';
    final toggling = context.select<InboxCubit, bool>(
      (c) => c.state.toggling.contains(_key(item)),
    );
    final preview = item.lastMessage.trim().isNotEmpty
        ? item.lastMessage.trim()
        : (item.reason.trim().isNotEmpty
              ? item.reason.trim()
              : Strings.noRecentMessage);
    final hasTime = item.lastSeen != null || item.escalatedAt != null;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '$name, ${item.platform == 'whatsapp' ? Strings.whatsapp : Strings.facebook}, '
          '$preview, ${isOpen ? Strings.humanHandler : (isBot ? Strings.botHandler : Strings.closed)}',
      onTap: () => _open(context),
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: InkWell(
            onTap: () => _open(context),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
                vertical: AppSpacing.vertical8,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
                border: isOpen
                    ? const BorderDirectional(
                        start: BorderSide(
                          color: AppColors.alertAmber,
                          width: 4,
                        ),
                      )
                    : Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                boxShadow: [AppShadow.card],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.innerCardPadding,
                  AppSpacing.vertical12,
                  AppSpacing.sm,
                  AppSpacing.vertical12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: scheme.primaryContainer,
                          child: hasName
                              ? Text(
                                  _initials(name),
                                  style: context.theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                )
                              : Icon(
                                  Icons.person_outline,
                                  color: scheme.onPrimaryContainer,
                                ),
                        ),
                        if (isOpen)
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.alertAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: ChannelChip(item.platform),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: isOpen
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isOpen
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              if (hasTime) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  Strings.relativeTime(item.sortAt),
                                  style: context.theme.textTheme.labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusChip(item: item),
                        const SizedBox(height: AppSpacing.xs),
                        _ToggleButton(
                          item: item,
                          toggling: toggling,
                          onTakeOver: () => _takeOver(context),
                          onGiveBack: () => _confirmGiveBack(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return Strings.initial(parts[0]) + Strings.initial(parts[1]);
    }
    return Strings.initial(parts[0]);
  }

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
    context.read<InboxCubit>().setAiMode(widget.item, ChatMode.human);
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final Conversation item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final (label, color) = switch (item.status) {
      'open' => (Strings.humanHandler, AppColors.alertAmber),
      'active' => (Strings.botHandler, scheme.primary),
      _ => (Strings.closed, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: context.theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.item,
    required this.toggling,
    required this.onTakeOver,
    required this.onGiveBack,
  });

  final Conversation item;
  final bool toggling;
  final VoidCallback onTakeOver;
  final VoidCallback onGiveBack;

  @override
  Widget build(BuildContext context) {
    if (toggling) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final human = item.mode == ChatMode.human;
    return IconButton(
      tooltip: human ? Strings.activateBot : Strings.takeOver,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      icon: Icon(human ? Icons.smart_toy_outlined : Icons.person_outline),
      onPressed: human ? onGiveBack : onTakeOver,
    );
  }
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
        vertical: AppSpacing.vertical8,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
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
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.forum_outlined,
            size: 40,
            color: scheme.onPrimaryContainer,
          ),
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
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.vertical8,
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_off_rounded,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  Strings.notificationsOff,
                  style: context.theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSecondaryContainer,
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
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.bubble)),
            border: Border.all(color: context.scheme.outlineVariant, width: 1),
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
                style: context.theme.textTheme.labelSmall?.copyWith(
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
