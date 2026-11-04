import 'package:cm_app/app/app_drawer.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/motion_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/api/models.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Premium dashboard: daily command center for community managers.
/// Every button navigates to a real screen; nothing is a stub.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<EscalationsCubit, EscalationsState>(
      builder: (context, state) {
        final openItems = state.items.where((i) => i.status == 'open').toList();
        final closedItems = state.items
            .where((i) => i.status == 'closed')
            .toList();
        final under15 = openItems.where((i) {
          return DateTime.now().difference(i.escalatedAt).inMinutes < 15;
        }).length;
        final today = DateTime.now();
        final handledToday = closedItems.where((i) {
          final d = i.escalatedAt;
          return d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        }).length;

        // Priority queue: oldest open escalations first (no backend priority
        // field exists yet, so oldest-waits-longest is the fair rule).
        final priorityItems = List<Escalation>.from(openItems)
          ..sort((a, b) => a.escalatedAt.compareTo(b.escalatedAt));

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Text(
              Strings.dashboardTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            actions: [
              SpinRefreshButton(
                onPressed: () => context.read<EscalationsCubit>().load(),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ProfileAvatar(),
            ],
          ),
          body: Container(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceDim,
            child: SafeArea(
              child: _DashboardBody(
                state: state,
                openItems: openItems,
                closedItems: closedItems,
                under15: under15,
                handledToday: handledToday,
                priorityItems: priorityItems,
                theme: theme,
                scheme: scheme,
              ),
            ),
          ),
          floatingActionButton: openItems.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => context.go('/escalations'),
                  icon: const Icon(Icons.list),
                  label: Text(
                    'Voir les ${openItems.length} ouverte${openItems.length > 1 ? 's' : ''}',
                  ),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.button),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.openItems,
    required this.closedItems,
    required this.under15,
    required this.handledToday,
    required this.priorityItems,
    required this.theme,
    required this.scheme,
  });

  final EscalationsState state;
  final List<Escalation> openItems;
  final List<Escalation> closedItems;
  final int under15;
  final int handledToday;
  final List<Escalation> priorityItems;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.items.isEmpty) {
      return const _SkeletonDashboard();
    }

    if (state.error != null && state.items.isEmpty) {
      return _ErrorState(
        theme: theme,
        scheme: scheme,
        message: state.error!,
        onRetry: () => context.read<EscalationsCubit>().load(),
      );
    }

    if (state.items.isEmpty && state.error == null) {
      return _EmptyDashboard();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Welcome + last refreshed
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              AppSpacing.vertical12,
              AppSpacing.pageGutter,
              AppSpacing.vertical16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de bord',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    LiveDot(color: scheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.items.length} escalade'
                            '${state.items.length > 1 ? 's' : ''} au total · '
                            '${Strings.liveLabel.toLowerCase()}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (state.items.isNotEmpty && state.error == null)
                            Text(
                              'Dernière actualisation : il y a peu',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Stat cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
          ),
          sliver: SliverToBoxAdapter(
            child: _StatRow(
              openCount: openItems.length,
              closedCount: closedItems.length,
              under15: under15,
              total: state.items.length,
              handledToday: handledToday,
              theme: theme,
              scheme: scheme,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        // Priority queue: à traiter en priorité
        if (openItems.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                theme: theme,
                title: Strings.priorityQueue,
                subtitle: Strings.priorityQueueSubtitle,
                onViewAll: () => context.go('/escalations'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
            ),
            sliver: SliverToBoxAdapter(
              child: _PriorityList(
                items: priorityItems.take(5).toList(),
                theme: theme,
                scheme: scheme,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
        // Quick actions (only real destinations)
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              theme: theme,
              title: 'Actions',
              subtitle: 'Gérer les escalades',
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
          ),
          sliver: SliverToBoxAdapter(
            child: _QuickActions(
              onViewEscalations: () => context.go('/escalations'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        // Recent activity (real items only)
        if (state.items.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                theme: theme,
                title: Strings.recentActivity,
                subtitle: Strings.viewAll,
                onViewAll: () => context.go('/escalations'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
            ),
            sliver: SliverToBoxAdapter(
              child: _RecentList(
                items: state.items,
                theme: theme,
                scheme: scheme,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: AppSpacing.vertical24 + AppSpacing.pageGutter,
            ),
          ),
        ],
      ],
    );
  }
}

class _SkeletonDashboard extends StatelessWidget {
  const _SkeletonDashboard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: [
        Container(
          height: 24,
          width: 200,
          color: scheme.surfaceContainerHigh,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 80,
          color: scheme.surfaceContainerHigh,
        ),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(4, (i) => _SkeletonCard(scheme: scheme)),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      height: 140,
      color: scheme.surfaceContainerHigh,
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Center(
      child: Column(
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
              Icons.inbox_outlined,
              size: 40,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.vertical16),
          Text(
            Strings.noEscalations,
            style: themeTextStyle(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Aucune conversation n\u2019a \u00e9t\u00e9 escalad\u00e9e pour le moment.',
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

TextStyle themeTextStyle(BuildContext context) {
  return context.theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w700,
    color: context.scheme.onSurface,
  ) ??
      const TextStyle(
        fontWeight: FontWeight.w700,
      );
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.openCount,
    required this.closedCount,
    required this.under15,
    required this.total,
    required this.handledToday,
    required this.theme,
    required this.scheme,
  });

  final int openCount;
  final int closedCount;
  final int under15;
  final int total;
  final int handledToday;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: Strings.openEscalations,
                value: openCount,
                delta: under15 > 0
                    ? '$under15 urgente${under15 > 1 ? 's' : ''}'
                    : 'Aucune urgente',
                color: AppColors.alertAmber,
                icon: Icons.error_outline,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                title: Strings.closedEscalations,
                value: closedCount,
                delta: 'r\u00e9solues',
                color: scheme.primary,
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total',
                value: total,
                delta: 'escalades',
                color: scheme.primary,
                icon: Icons.list_alt,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                title: 'Traitees aujourd hui',
                value: handledToday,
                delta: 'conversations',
                color: scheme.primary,
                icon: Icons.chat_bubble_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.color,
    required this.icon,
    this.suffix = '',
  });

  final String title;
  final int value;
  final String suffix;
  final String delta;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [AppShadow.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                builder: (context, t, child) =>
                    Transform.scale(scale: t, child: child),
                child: Icon(icon, color: color, size: 18),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: still ? value : 0, end: value),
            duration: still ? Duration.zero : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '$v$suffix',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            delta,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.theme,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  final ThemeData theme;
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              Strings.viewAll,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onViewEscalations});

  final VoidCallback onViewEscalations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.2,
      children: [
        _ActionTile(
          icon: Icons.list_alt,
          label: 'Voir les escalades',
          color: scheme.primary,
          glow: AppColors.lightPrimaryGlow,
          onTap: onViewEscalations,
        ),
        _ActionTile(
          icon: Icons.refresh,
          label: 'Actualiser',
          color: AppColors.alertAmber,
          glow: AppColors.lightAmberGlow,
          onTap: () => context.read<EscalationsCubit>().load(),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.glow,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [AppShadow.card],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, color: color, size: 22)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.items,
    required this.theme,
    required this.scheme,
  });

  final List<Escalation> items;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Escalation>.from(items)
      ..sort((a, b) => b.escalatedAt.compareTo(a.escalatedAt));
    final recent = sorted.take(5).toList();

    return Column(
      children: recent
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RecentRow(item: item, theme: theme, scheme: scheme),
            ),
          )
          .toList(),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.item,
    required this.theme,
    required this.scheme,
  });

  final Escalation item;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isOpen = item.status == 'open';
    final name = Strings.customerLabel(item.customerName, item.senderId);
    final time = Strings.relativeTime(item.escalatedAt);
    final channel = item.platform == 'whatsapp'
        ? Strings.whatsapp
        : Strings.facebook;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isOpen)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.alertAmber,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surfaceContainer,
                      width: 2,
                    ),
                  ),
                ),
              ),
            Positioned(right: -4, top: -4, child: ChannelChip(item.platform)),
          ],
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$channel \u00b7 $time',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOpen
                ? AppColors.alertAmber.withValues(alpha: 0.12)
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOpen
                  ? AppColors.alertAmber.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            isOpen ? Strings.open : Strings.closed,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOpen ? AppColors.alertAmber : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({
    required this.items,
    required this.theme,
    required this.scheme,
  });

  final List<Escalation> items;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isOpen = item.status == 'open';
        final name = Strings.customerLabel(item.customerName, item.senderId);
        final minutes = DateTime.now().difference(item.escalatedAt).inMinutes;
        final timeLabel = minutes < 60
            ? 'il y a $minutes min'
            : (minutes ~/ 60 < 24
                ? 'il y a ${minutes ~/ 60} h'
                : 'il y a ${minutes ~/ 60 ~/ 24} j');
        final channel = item.platform == 'whatsapp'
            ? Strings.whatsapp
            : Strings.facebook;

        return InkWell(
          onTap: () => context.push('/chat/${item.platform}/${item.senderId}'),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.alertAmber.withValues(alpha: 0.2)
                          : scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: index == 0
                              ? AppColors.alertAmber
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.alertAmber.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              child: Text(
                                'Prioritaire',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.alertAmber,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              channel == Strings.whatsapp
                                  ? Icons.message
                                  : Icons.facebook,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '$channel \u00b7 $timeLabel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.theme,
    required this.scheme,
    required this.message,
    required this.onRetry,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Erreur',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [AppShadow.card],
        ),
        child: Center(
          child: Text(
            'U',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
