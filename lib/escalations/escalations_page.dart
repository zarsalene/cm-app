import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Escalation list. Reads [EscalationsCubit] and [AuthBloc] from the tree.
class EscalationsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.escalationsTitle),
        actions: [
          IconButton(
            tooltip: Strings.logout,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<EscalationsCubit, EscalationsState>(
          builder: (context, state) {
            if (state.items.isEmpty && state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () => context.read<EscalationsCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.error case final error?) _ErrorBanner(error: error),
                  if (state.items.isEmpty && state.error == null)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: Text(Strings.noEscalations)),
                    ),
                  for (final item in state.items) _Row(item: item),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const new({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.read<EscalationsCubit>().load(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, kMinInteractiveDimension),
            ),
            child: const Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const new({required this.item});

  final Escalation item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = item.status == 'open';
    final name = Strings.customerLabel(item.customerName, item.senderId);
    final time = Strings.relativeTime(item.escalatedAt);
    final channel = item.platform == 'whatsapp'
        ? Strings.whatsapp
        : Strings.facebook;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '$name, $channel, ${item.reason}, $time, '
          '${isOpen ? Strings.open : Strings.closed}',
      onTap: () => _open(context),
      child: InkWell(
        onTap: () => _open(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChannelChip(item.platform),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        item.reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Flexible: time wraps at 200% text scale.
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _StatusDot(isOpen: isOpen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<EscalationsCubit>();
    final sender = Uri.encodeComponent(item.senderId);
    await context.push('/chat/${item.platform}/$sender');
    // The conversation may have changed (give back, new reply).
    await cubit.load();
  }
}

class _StatusDot extends StatelessWidget {
  const new({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOpen ? AppColors.alert : null,
        border: isOpen
            ? null
            : Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: const SizedBox.square(dimension: AppSpacing.md - AppSpacing.xs),
    );
  }
}
