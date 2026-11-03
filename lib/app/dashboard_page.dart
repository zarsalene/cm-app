import 'package:cm_app/app/app_drawer.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/escalations/escalations_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Premium dashboard: welcome header, stat cards, quick actions,
/// recent activity and a navigation drawer.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
          _AppBarAction(
            icon: Icons.notifications_none,
            activeIcon: Icons.notifications,
            label: 'Alertes',
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          _ProfileAvatar(),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceDim,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Welcome
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
                        '${Strings.welcomeBack} l\'équipe CM.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Voici l\'état de vos escalades et conversations.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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
                  child: _StatRow(scheme: scheme, theme: theme),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              // Quick actions
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageGutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    theme: theme,
                    title: 'Actions rapides',
                    subtitle: 'Accédez aux fonctions principales',
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
                    onNewEscalation: () {
                      context.go('/escalations');
                    },
                    onViewEscalations: () {
                      context.go('/escalations');
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              // Recent activity
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageGutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    theme: theme,
                    title: Strings.recentActivity,
                    subtitle: Strings.viewAll,
                    onViewAll: () {
                      context.go('/escalations');
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageGutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: _RecentList(scheme: scheme, theme: theme),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: AppSpacing.vertical24 + AppSpacing.pageGutter,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/escalations');
        },
        icon: const Icon(Icons.add),
        label: Text(Strings.newEscalation),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IconButton(
      icon: Icon(icon, color: scheme.onSurface),
      onPressed: onTap,
      tooltip: label,
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

class _StatRow extends StatelessWidget {
  const _StatRow({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: Strings.openEscalations,
                    value: '12',
                    delta: '+3 aujourd\'hui',
                    color: AppColors.alertAmber,
                    glow: AppColors.lightAmberGlow,
                    icon: Icons.error_outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: Strings.closedEscalations,
                    value: '84',
                    delta: '+12 cette semaine',
                    color: AppColors.lightPrimary,
                    glow: AppColors.lightTealGlow,
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            if (!isWide) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: Strings.avgResponseTime,
                      value: '2 min 4 s',
                      delta: '-15 % vs semaine',
                      color: AppColors.whatsapp,
                      glow: AppColors.lightAmberGlow,
                      icon: Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      title: Strings.activeChats,
                      value: '6',
                      delta: 'en cours',
                      color: AppColors.facebook,
                      glow: AppColors.lightTealGlow,
                      icon: Icons.chat,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: Strings.avgResponseTime,
                      value: '2 min 4 s',
                      delta: '-15 % vs semaine',
                      color: AppColors.whatsapp,
                      glow: AppColors.lightAmberGlow,
                      icon: Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      title: Strings.activeChats,
                      value: '6',
                      delta: 'en cours',
                      color: AppColors.facebook,
                      glow: AppColors.lightTealGlow,
                      icon: Icons.chat,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.color,
    required this.glow,
    required this.icon,
  });

  final String title;
  final String value;
  final String delta;
  final Color color;
  final Color glow;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: glow, blurRadius: 12, offset: Offset.zero),
                  ],
                ),
                child: Center(child: Icon(icon, color: color, size: 18)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
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
        Column(
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
  const _QuickActions({
    required this.onNewEscalation,
    required this.onViewEscalations,
  });

  final VoidCallback onNewEscalation;
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
      childAspectRatio: 1.55,
      children: [
        _ActionTile(
          icon: Icons.add_circle_outline,
          label: 'Nouvelle escalade',
          color: AppColors.alertAmber,
          glow: AppColors.lightAmberGlow,
          onTap: onNewEscalation,
        ),
        _ActionTile(
          icon: Icons.list_alt,
          label: 'Toutes les escalades',
          color: AppColors.lightPrimary,
          glow: AppColors.lightTealGlow,
          onTap: onViewEscalations,
        ),
        _ActionTile(
          icon: Icons.chat_bubble_outline,
          label: 'Conversations',
          color: AppColors.facebook,
          glow: AppColors.lightTealGlow,
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.notifications,
          label: 'Alertes actives',
          color: AppColors.whatsapp,
          glow: AppColors.lightAmberGlow,
          onTap: () {},
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
                  boxShadow: [
                    BoxShadow(color: glow, blurRadius: 12, offset: Offset.zero),
                  ],
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
  const _RecentList({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final items = [
      _RecentItem(
        name: 'Sarah Ben Ali',
        platform: 'whatsapp',
        time: 'il y a 5 min',
        status: 'open',
      ),
      _RecentItem(
        name: 'Karim Ghozzi',
        platform: 'facebook',
        time: 'il y a 1 h',
        status: 'open',
      ),
      _RecentItem(
        name: 'Fatma Trabelsi',
        platform: 'whatsapp',
        time: 'il y a 3 h',
        status: 'closed',
      ),
      _RecentItem(
        name: 'Omar Jaziri',
        platform: 'facebook',
        time: 'Hier',
        status: 'closed',
      ),
    ];
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RecentRow(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _RecentItem {
  const _RecentItem({
    required this.name,
    required this.platform,
    required this.time,
    required this.status,
  });
  final String name;
  final String platform;
  final String time;
  final String status; // 'open' | 'closed'
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item});

  final _RecentItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOpen = item.status == 'open';
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
                item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
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
          item.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            ChannelChip(item.platform),
            const SizedBox(width: AppSpacing.sm),
            Text(
              item.time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
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
