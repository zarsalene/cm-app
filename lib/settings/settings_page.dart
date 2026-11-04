import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/auth/token_store.dart';
import 'package:cm_app/core/theme_mode_service.dart';
import 'package:cm_app/push/push_service.dart';
import 'package:cm_app/settings/settings_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(
        theme: context.read<ThemeModeService>(),
        push: context.read<PushService>(),
        auth: context.read<AuthBloc>(),
      )..checkNotifications(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late final SettingsCubit _cubit = context.read<SettingsCubit>();
  bool? _storageWorking;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    final store = context.read<TokenStore>();
    final working = await store.testStorage();
    if (mounted) setState(() => _storageWorking = working);
  }

  Future<void> _resetSession() async {
    final store = context.read<TokenStore>();
    await store.delete();
    if (!mounted) return;
    context.read<SettingsCubit>().onLogoutRequested();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              // --- Appearance ---
              _Section(title: Strings.appearance),
              _Tile(
                icon: Icons.brightness_6_outlined,
                label: Strings.themeMode,
                subtitle: _themeLabel(state.themeMode),
                onTap: () => _showThemePicker(context, state.themeMode),
              ),
              _Tile(
                icon: Icons.language_outlined,
                label: Strings.language,
                subtitle: '${state.languageCode.toUpperCase()} (Fran\u00e7ais)',
                onTap: null,
              ),

              const Divider(height: 1),

              // --- Notifications ---
              _Section(title: Strings.notifications),
              SwitchListTile(
                title: Text(Strings.pushNotifications),
                subtitle: Text(
                  state.pushAvailable
                      ? state.notificationsEnabled
                          ? Strings.pushActive
                          : Strings.pushOff
                      : Strings.pushUnavailable,
                ),
                value: state.notificationsEnabled,
                onChanged: state.pushAvailable
                    ? (v) => _cubit.onNotificationsToggled(v)
                    : null,
                activeColor: scheme.primary,
              ),

              const Divider(height: 1),

              // --- Account ---
              _Section(title: Strings.account),
              _Tile(
                icon: Icons.logout,
                label: Strings.logout,
                textColor: scheme.error,
                iconColor: scheme.error,
                onTap: () => _confirmLogout(context),
              ),
              _Tile(
                icon: Icons.logout,
                label: Strings.resetSession,
                subtitle: Strings.resetSessionSubtitle,
                textColor: scheme.error,
                iconColor: scheme.error,
                onTap: () => _confirmReset(context),
              ),

              const Divider(height: 1),

              // --- Storage ---
              _Section(title: 'Stockage'),
              _Tile(
                icon: _storageWorking == true
                    ? Icons.check_circle
                    : _storageWorking == false
                        ? Icons.error
                        : Icons.cloud_queue,
                label: 'Mémorisation des identifiants',
                subtitle: _storageWorking == true
                    ? 'Le téléphone peut sauvegarder votre session'
                    : _storageWorking == false
                        ? 'Le stockage sécurisé ne fonctionne pas'
                        : 'Vérification en cours…',
                textColor: _storageWorking == true
                    ? null
                    : _storageWorking == false
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                iconColor: _storageWorking == true
                    ? scheme.primary
                    : _storageWorking == false
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                onTap: _storageWorking == null ? _checkStorage : null,
              ),

              const Divider(height: 1),

              // --- About ---
              _Section(title: Strings.about),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return _Tile(
                    icon: Icons.info_outline,
                    label: Strings.appName,
                    subtitle:
                        info != null
                            ? '${Strings.version} ${info.version} (${info.buildNumber})'
                            : '',
                    onTap: null,
                  );
                },
              ),
              _Tile(
                icon: Icons.copyright_outlined,
                label: Strings.developedByMicrozed,
                subtitle: Strings.microzed,
                onTap: null,
              ),
            ],
          );
        },
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Strings.themeLight;
      case ThemeMode.dark:
        return Strings.themeDark;
      case ThemeMode.system:
        return Strings.themeSystem;
    }
  }

  void _showThemePicker(BuildContext context, ThemeMode current) {
    final scheme = context.scheme;
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    Strings.themeMode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                ...[
                  (Strings.themeSystem, ThemeMode.system),
                  (Strings.themeLight, ThemeMode.light),
                  (Strings.themeDark, ThemeMode.dark),
                ].map(
                  (entry) => ListTile(
                    leading: Radio<ThemeMode>(
                      value: entry.$2,
                      groupValue: state.themeMode,
                      onChanged: (mode) {
                        if (mode == null) return;
                        context.read<SettingsCubit>().onThemeChanged(mode);
                        Navigator.of(context).pop();
                      },
                    ),
                    title: Text(entry.$1),
                  ),
                ),
                const SizedBox(height: AppSpacing.pageGutter),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final scheme = context.scheme;
    showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.dialog)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 48, color: scheme.error),
              const SizedBox(height: AppSpacing.vertical16),
              Text(
                Strings.logout,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: AppSpacing.vertical12),
              Text(
                'Vous serez d\u00e9connect\u00e9(e) de votre compte.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
      ),
    ).then((ok) {
      if ((ok ?? false) && !kIsWeb) {
        context.read<SettingsCubit>().onLogoutRequested();
      }
    });
  }

  void _confirmReset(BuildContext context) {
    final scheme = context.scheme;
    showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.dialog)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.innerCardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever, size: 48, color: scheme.error),
              const SizedBox(height: AppSpacing.vertical16),
              Text(
                'Réinitialiser la session',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: AppSpacing.vertical12),
              Text(
                'Le token stocké sera effacé. Vous devrez vous reconnecter.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
      ),
    ).then((ok) {
      if ((ok ?? false) && !kIsWeb) {
        _resetSession();
      }
    });
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.vertical16,
        AppSpacing.pageGutter,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.subtitle = '',
    this.textColor,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: textColor ?? scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle:
          subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
      onTap: onTap,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.xs,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
    );
  }
}
