import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Displays the logged-in user's profile.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final username = state is Authenticated ? state.username : '\u2014';
        final scheme = context.scheme;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(Strings.profile),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [AppShadow.card],
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.vertical24),
                Text(
                  username,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'cm@z-smart-cm.tn',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ProfileRow(
                  icon: Icons.person_outline,
                  label: 'Nom d\u2019utilisateur',
                  value: username,
                ),
                _ProfileRow(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value: 'cm@z-smart-cm.tn',
                ),
                _ProfileRow(
                  icon: Icons.lock_outline,
                  label: 'Mot de passe',
                  value: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
        ),
      ),
    );
  }
}
