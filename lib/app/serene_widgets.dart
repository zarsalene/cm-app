import 'package:cm_app/api/models.dart';
import 'package:cm_app/app/motion_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared pieces of the "Serene Operations" design. Colors, radii and type
/// come from the theme: nothing here works in dark mode only.

/// Minutes of waiting after which a customer turns from amber to red. The
/// backend has no SLA field, so this is a client rule.
const urgentWaitMinutes = 30;

enum WaitSeverity { waiting, urgent }

WaitSeverity waitSeverity(int minutes) =>
    minutes >= urgentWaitMinutes ? WaitSeverity.urgent : WaitSeverity.waiting;

/// Tinted pill: [color] is the text and icon color, readable on the theme;
/// the fill is the same color at low alpha.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.icon,
    this.dot = false,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 4,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            if (dot) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 8),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "18m d'attente": amber, red once [urgentWaitMinutes] is reached.
class WaitPill extends StatelessWidget {
  const WaitPill({required this.minutes, super.key});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = waitSeverity(minutes) == WaitSeverity.urgent
        ? context.urgent
        : context.amber;
    return StatusPill(
      label: Strings.waiting(minutes),
      color: color,
      icon: Icons.schedule,
    );
  }
}

/// Round initials avatar with the channel badge on its corner.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    required this.platform,
    this.size = 48,
    super.key,
  });

  final String name;
  final String platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    Strings.initials(name),
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: ChannelBadge(platform, ringColor: scheme.surfaceContainer),
          ),
        ],
      ),
    );
  }
}

/// 20 dp channel marker: WhatsApp green or Messenger blue, with an icon.
class ChannelBadge extends StatelessWidget {
  const ChannelBadge(this.platform, {this.ringColor, super.key});

  final String platform;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final (name, icon, background, foreground) = switch (platform) {
      'facebook' => (
        Strings.facebook,
        Icons.bolt,
        AppColors.facebook,
        AppColors.onFacebook,
      ),
      'whatsapp' => (
        Strings.whatsapp,
        Icons.chat_bubble,
        AppColors.whatsapp,
        AppColors.onWhatsapp,
      ),
      _ => (
        platform,
        Icons.forum,
        context.scheme.secondaryContainer,
        context.scheme.onSecondaryContainer,
      ),
    };
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: ringColor == null
              ? null
              : Border.all(color: ringColor!, width: 2),
        ),
        child: SizedBox.square(
          dimension: 22,
          child: Icon(icon, size: 12, color: foreground),
        ),
      ),
    );
  }
}

/// Level 1 surface with an optional colored stripe on the leading edge.
class ThreadCard extends StatelessWidget {
  const ThreadCard({
    required this.child,
    this.stripe,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.innerCardPadding),
    super.key,
  });

  final Widget child;
  final Color? stripe;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: scheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: padding.add(
                EdgeInsetsDirectional.only(start: stripe == null ? 0 : 4),
              ),
              child: child,
            ),
            if (stripe != null)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: stripe!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bot / human segmented switch. Tapping the segment already selected does
/// nothing; while [busy] no segment reacts.
class HandoffSwitch extends StatelessWidget {
  const HandoffSwitch({
    required this.mode,
    required this.onChanged,
    this.busy = false,
    super.key,
  });

  final ChatMode mode;
  final bool busy;
  final ValueChanged<ChatMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: Strings.botAuto,
              icon: Icons.smart_toy_outlined,
              selected: mode == ChatMode.bot,
              selectedColor: scheme.surfaceContainerHighest,
              onSelectedColor: scheme.onSurface,
              onTap: busy ? null : () => onChanged(ChatMode.bot),
            ),
            _Segment(
              label: Strings.youActive,
              dotColor: context.amber,
              selected: mode == ChatMode.human,
              selectedColor: scheme.primaryContainer,
              onSelectedColor: scheme.onPrimaryContainer,
              onTap: busy ? null : () => onChanged(ChatMode.human),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onSelectedColor,
    required this.onTap,
    this.icon,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color onSelectedColor;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final foreground = selected ? onSelectedColor : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: selected ? null : onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: selected ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            child: AnimatedContainer(
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 36,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2,
              ),
              decoration: BoxDecoration(
                color: selected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: AppSpacing.xs + 2),
                  ],
                  if (dotColor != null && selected) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                  ],
                  Text(
                    label,
                    style: context.theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
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

/// Bottom navigation: dashboard, inbox, settings. [current] is the index of
/// the page that shows it.
class AppNavBar extends StatelessWidget {
  const AppNavBar({required this.current, super.key});

  final int current;

  static const _routes = ['/', '/inbox', '/settings'];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current,
      onDestinationSelected: (i) {
        if (i != current) context.go(_routes[i]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Strings.navDashboard,
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: Strings.navInbox,
        ),
        NavigationDestination(
          icon: Icon(Icons.tune),
          label: Strings.navSettings,
        ),
      ],
    );
  }
}

/// Top bar of the main pages: brand mark (opens the menu when the page has
/// one), name with the live status, alert state and the profile shortcut.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({this.notificationsOff = false, super.key});

  final bool notificationsOff;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.theme.textTheme;
    final hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Semantics(
                button: hasDrawer,
                label: Strings.appName,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: hasDrawer
                      ? () => Scaffold.of(context).openDrawer()
                      : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: ExcludeSemantics(
                          child: Text(
                            'Z',
                            style: text.titleLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            Strings.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm - 1,
                              vertical: 2,
                            ),
                            child: Text(
                              Strings.directTag,
                              style: text.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        LiveDot(color: scheme.primary, size: 6),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          Strings.online,
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (notificationsOff)
                IconButton(
                  tooltip: Strings.notificationsOff,
                  icon: Icon(
                    Icons.notifications_off_outlined,
                    color: context.amber,
                  ),
                  onPressed: () => context.go('/settings'),
                ),
              IconButton.filledTonal(
                tooltip: Strings.profile,
                icon: const Icon(Icons.person_outline),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
