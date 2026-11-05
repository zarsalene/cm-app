import 'dart:async';

import 'package:cm_app/api/models.dart';
import 'package:cm_app/app/app_drawer.dart';
import 'package:cm_app/app/dashboard_strings.dart';
import 'package:cm_app/app/motion_widgets.dart';
import 'package:cm_app/app/serene_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/inbox/inbox_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Minutes after which an open conversation counts as "waiting too long" in
/// the hero card. Client rule: the backend has no SLA field.
const _warnAfterMinutes = 15;

/// Minutes since the escalation (or last message), or null when unknown.
int? _waitMinutes(Conversation c, DateTime now) {
  final at = c.escalatedAt ?? c.lastSeen;
  if (at == null) return null;
  final minutes = now.difference(at).inMinutes;
  return minutes < 0 ? 0 : minutes;
}

final _rtlChar = RegExp(r'[֐-׿؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');

/// Direction of one piece of customer text: Arabic script reads right-to-left.
TextDirection _directionOf(String text) =>
    _rtlChar.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;

void _openChat(BuildContext context, Conversation item) => unawaited(
  context.push('/chat/${item.platform}/${Uri.encodeComponent(item.senderId)}'),
);

/// Daily command center for community managers: what waits, what the bot
/// handles, and the shortest way to the next customer.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        final now = DateTime.now();
        final openItems = state.conversations
            .where((i) => i.status == 'open')
            .toList();
        final botItems = state.conversations
            .where((i) => i.status == 'active')
            .toList();
        final closedItems = state.conversations
            .where((i) => i.status == 'closed')
            .toList();
        final waits = openItems
            .map((i) => _waitMinutes(i, now))
            .whereType<int>()
            .toList();
        final over15 = waits.where((m) => m >= _warnAfterMinutes).length;
        final under15 = waits.length - over15;
        final averageWait = waits.isEmpty
            ? 0
            : (waits.reduce((a, b) => a + b) / waits.length).round();
        final handledToday = closedItems.where((i) {
          final d = i.escalatedAt ?? i.lastSeen;
          return d != null &&
              d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        }).length;

        // Priority queue: oldest open escalations first (no backend priority
        // field exists yet, so oldest-waits-longest is the fair rule).
        final priorityItems = List<Conversation>.from(openItems)
          ..sort(
            (a, b) => (a.escalatedAt ?? a.sortAt).compareTo(
              b.escalatedAt ?? b.sortAt,
            ),
          );
        final anyUrgent = waits.any(
          (m) => waitSeverity(m) == WaitSeverity.urgent,
        );

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: BrandAppBar(notificationsOff: state.notificationsOff),
          bottomNavigationBar: const AppNavBar(current: 0),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: openItems.isEmpty
              ? null
              : _TriageButton(count: openItems.length, urgent: anyUrgent),
          body: _DashboardBody(
            state: state,
            openCount: openItems.length,
            botCount: botItems.length,
            over15: over15,
            under15: under15,
            averageWait: averageWait,
            handledToday: handledToday,
            priorityItems: priorityItems.take(5).toList(),
          ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.openCount,
    required this.botCount,
    required this.over15,
    required this.under15,
    required this.averageWait,
    required this.handledToday,
    required this.priorityItems,
  });

  final InboxState state;
  final int openCount;
  final int botCount;
  final int over15;
  final int under15;
  final int averageWait;
  final int handledToday;
  final List<Conversation> priorityItems;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.conversations.isEmpty) {
      return const _SkeletonDashboard();
    }
    if (state.error != null && state.conversations.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => context.read<InboxCubit>().load(),
      );
    }
    if (state.conversations.isEmpty) return const _EmptyDashboard();

    final scheme = context.scheme;
    final recent = List<Conversation>.from(state.conversations)
      ..sort((a, b) => b.sortAt.compareTo(a.sortAt));

    return RefreshIndicator(
      onRefresh: () => context.read<InboxCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom room: the floating triage button sits over the list.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          AppSpacing.sm,
          AppSpacing.pageGutter,
          96,
        ),
        children: [
          _Greeting(total: state.conversations.length),
          const SizedBox(height: AppSpacing.vertical16),
          ThreadCard(
            stripe: scheme.primary,
            onTap: () => context.go('/inbox'),
            child: _OpenHero(open: openCount, over15: over15),
          ),
          const SizedBox(height: AppSpacing.vertical12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    title: DashboardStrings.byBot,
                    value: botCount,
                    unit: DashboardStrings.activeUnit,
                    icon: Icons.smart_toy_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.vertical12),
                Expanded(
                  child: _StatTile(
                    title: DashboardStrings.handledToday,
                    value: handledToday,
                    unit: DashboardStrings.conversationsUnit,
                    icon: Icons.task_alt,
                    color: context.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.vertical12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    title: DashboardStrings.averageWait,
                    value: averageWait,
                    unit: DashboardStrings.minuteUnit,
                    icon: Icons.timer_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.vertical12),
                Expanded(
                  child: _StatTile(
                    title: DashboardStrings.underFifteen,
                    value: under15,
                    unit: DashboardStrings.openUnit,
                    icon: Icons.verified_outlined,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (priorityItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              title: DashboardStrings.priorityTitle,
              leading: Icon(Icons.priority_high, color: context.amber),
              trailing: Text(
                DashboardStrings.waitingOrder,
                style: context.theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.vertical12),
            for (final item in priorityItems)
              _PriorityCard(
                item: item,
                busy: state.toggling.contains(
                  '${item.platform}/${item.senderId}',
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.vertical12),
          _SectionHeader(
            title: Strings.recentActivity,
            trailing: TextButton(
              onPressed: () => context.go('/inbox'),
              child: const Text(DashboardStrings.viewAll),
            ),
          ),
          const SizedBox(height: AppSpacing.vertical12),
          _RecentCard(items: recent.take(5).toList()),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final text = context.theme.textTheme;
    final scheme = context.scheme;
    final username = context.select<AuthBloc, String?>((b) {
      final s = b.state;
      return s is Authenticated ? s.username : null;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username == null
              ? DashboardStrings.helloAnonymous
              : DashboardStrings.hello(username),
          style: text.headlineMedium?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            LiveDot(color: scheme.primary, size: 6),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                DashboardStrings.totalLine(total),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated number; static when the user turned animations off.
class _Count extends StatelessWidget {
  const _Count(this.value, {this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: still ? value : 0, end: value),
      duration: still ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v', style: style),
    );
  }
}

class _OpenHero extends StatelessWidget {
  const _OpenHero({required this.open, required this.over15});

  final int open;
  final int over15;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DashboardStrings.openConversations,
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _Count(
                    open,
                    style: text.headlineLarge?.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (over15 > 0)
                    StatusPill(
                      label: DashboardStrings.overLimit(over15),
                      color: context.amber,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.hero),
          ),
          child: SizedBox.square(
            dimension: 56,
            child: Icon(Icons.inbox_outlined, color: scheme.primary, size: 28),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: text.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(icon, color: color, size: 22),
                ],
              ),
              const SizedBox(height: AppSpacing.vertical16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.xs + 2,
                children: [
                  _Count(
                    value,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    unit,
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            title,
            style: context.theme.textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Solid channel label: "WhatsApp" green or "Facebook" blue.
class _ChannelPill extends StatelessWidget {
  const _ChannelPill(this.platform);

  final String platform;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (platform) {
      'facebook' => (
        Strings.facebook,
        AppColors.facebook,
        AppColors.onFacebook,
      ),
      'whatsapp' => (
        Strings.whatsapp,
        AppColors.whatsapp,
        AppColors.onWhatsapp,
      ),
      _ => (
        platform,
        context.scheme.secondaryContainer,
        context.scheme.onSecondaryContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          label,
          style: context.theme.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.item, required this.busy});

  final Conversation item;
  final bool busy;

  Future<void> _sendBack(BuildContext context) async {
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
      await cubit.setAiMode(item, ChatMode.bot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final name = Strings.customerLabel(
      item.customerName,
      item.senderId,
      platform: item.platform,
    );
    final minutes = _waitMinutes(item, DateTime.now());
    final stripe =
        minutes != null && waitSeverity(minutes) == WaitSeverity.urgent
        ? context.urgent
        : context.amber;
    final detail = item.reason.trim().isNotEmpty
        ? item.reason.trim()
        : (item.lastMessage.trim().isNotEmpty
              ? item.lastMessage.trim()
              : Strings.noRecentMessage);
    const compact = Size(0, 48);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.vertical12),
      child: ThreadCard(
        stripe: stripe,
        onTap: () => _openChat(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: name, platform: item.platform, size: 44),
                const SizedBox(width: AppSpacing.vertical12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: _directionOf(name),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _ChannelPill(item.platform),
                    ],
                  ),
                ),
                if (minutes != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  WaitPill(minutes: minutes),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.vertical12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.vertical12),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '« $detail »',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: _directionOf(detail),
                    style: text.bodyMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.vertical12),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => _openChat(context, item),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text(DashboardStrings.reply),
                  style: FilledButton.styleFrom(
                    minimumSize: compact,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : () => unawaited(_sendBack(context)),
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const Text(DashboardStrings.sendBackToBot),
                  style: FilledButton.styleFrom(
                    minimumSize: compact,
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurfaceVariant,
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

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.items});

  final List<Conversation> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: scheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            _RecentRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item});

  final Conversation item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final channel = item.platform == 'whatsapp'
        ? Strings.whatsapp
        : Strings.facebook;
    final name = Strings.customerLabel(
      item.customerName,
      item.senderId,
      platform: item.platform,
    );
    final at = item.lastSeen ?? item.escalatedAt;
    final time = at == null
        ? Strings.noRecentMessage
        : Strings.relativeTime(at);
    final (statusLabel, statusColor, icon) = switch (item.status) {
      'open' => (Strings.humanHandler, context.amber, Icons.priority_high),
      'active' => (
        Strings.botHandler,
        scheme.primary,
        Icons.smart_toy_outlined,
      ),
      _ => (Strings.closed, scheme.primary, Icons.task_alt),
    };

    return InkWell(
      onTap: () => _openChat(context, item),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(icon, color: statusColor, size: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.vertical12),
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
                          textDirection: _directionOf(name),
                          style: text.titleMedium?.copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        time,
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$statusLabel · $channel',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

/// Floating pill to the inbox. The "Urgent" tag shows only when a customer
/// has waited past [urgentWaitMinutes].
class _TriageButton extends StatelessWidget {
  const _TriageButton({required this.count, required this.urgent});

  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return FloatingActionButton.extended(
      onPressed: () => context.go('/inbox'),
      shape: const StadiumBorder(),
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      icon: const Icon(Icons.flash_on),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(DashboardStrings.triage(count))),
          if (urgent) ...[
            const SizedBox(width: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.secondary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  DashboardStrings.urgent,
                  style: context.theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonDashboard extends StatelessWidget {
  const _SkeletonDashboard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    Widget block(double height, {double? width}) => DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: SizedBox(height: height, width: width ?? double.infinity),
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: [
        block(28, width: 200),
        const SizedBox(height: AppSpacing.md),
        block(96),
        const SizedBox(height: AppSpacing.vertical12),
        block(110),
        const SizedBox(height: AppSpacing.vertical12),
        block(140),
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 96,
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.vertical16),
          Text(Strings.noConversations, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Strings.noConversationsBody,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(DashboardStrings.errorTitle, style: text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}
