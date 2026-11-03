import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Navigation drawer (menu): profile header + destinations + logout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final username = context.select<AuthBloc, String?>((b) {
      final s = b.state;
      return s is Authenticated ? s.username : null;
    });

    return Drawer(
      backgroundColor: isDark(theme)
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      child: Column(
        children: [
          // Header: profile
          _DrawerHeader(
            username: username ?? 'Utilisateur',
            email: 'cm@z-smart-cm.tn',
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: Strings.dashboardTitle,
                  onTap: () {
                    context.pop();
                    context.go('/');
                  },
                ),
                _DrawerItem(
                  icon: Icons.report_outlined,
                  activeIcon: Icons.report,
                  label: Strings.escalationsTitle,
                  onTap: () {
                    context.pop();
                    context.go('/escalations');
                  },
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Conversations',
                  onTap: () {
                    context.pop();
                    context.go('/');
                  },
                ),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  label: 'Alertes',
                  onTap: () {
                    context.pop();
                    context.go('/');
                  },
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: Strings.profile,
                  onTap: () {
                    context.pop();
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: Strings.settings,
                  onTap: () {
                    context.pop();
                  },
                ),
                _DrawerItem(
                  icon: Icons.help_outline,
                  activeIcon: Icons.help,
                  label: Strings.help,
                  onTap: () {
                    context.pop();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _DrawerItem(
            icon: Icons.logout,
            activeIcon: Icons.logout,
            label: Strings.logout,
            textColor: scheme.error,
            iconColor: scheme.error,
            onTap: () => _logout(context),
          ),
          const SizedBox(height: AppSpacing.pageGutter),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // Dispatch logout and close the drawer. The router's authRedirect
    // automatically sends the user to /login once the state becomes
    // Unauthenticated — no manual navigation needed here.
    context.read<AuthBloc>().add(const LogoutRequested());
    Navigator.of(context).pop();
  }
}

bool isDark(ThemeData theme) => theme.brightness == Brightness.dark;

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.username, required this.email});

  final String username;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.vertical24,
        AppSpacing.pageGutter,
        AppSpacing.vertical24,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [AppShadow.card],
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
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
                Text(
                  username,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tc = textColor ?? scheme.onSurface;
    final ic = iconColor ?? scheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(activeIcon, color: ic, size: 22),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: tc,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
      tileColor: tc == scheme.error ? null : null,
    );
  }
}
