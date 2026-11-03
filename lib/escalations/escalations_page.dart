import 'dart:async';

import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/app/channel_chip.dart';
import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:cm_app/auth/auth_bloc.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EscalationsPage extends StatefulWidget {
  const EscalationsPage({super.key});

  @override
  State<EscalationsPage> createState() => _EscalationsPageState();
}

class _EscalationsPageState extends State<EscalationsPage>
    with WidgetsBindingObserver {
  late final EscalationsCubit _cubit = context.read<EscalationsCubit>();

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
        _cubit.startPolling();
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
        title: Text(
          Strings.escalationsTitle,
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        child: Column(
          children: [
            const _NotificationsBanner(),
            const _OfflineNotice(),
            Expanded(child: _List()),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EscalationsCubit, EscalationsState>(
      builder: (context, state) {
        if (state.items.isEmpty && state.loading) {
          return const _SkeletonList();
        }
        return RefreshIndicator(
          onRefresh: () => context.read<EscalationsCubit>().load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (state.error case final error?) _ErrorBanner(error: error),
              if (state.items.isEmpty && state.error == null)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.pageGutter),
                  child: _EmptyState(),
                ),
              if (state.items.isNotEmpty) ...[
                if (state.items.any((i) => i.status == 'open')) ...[
                  _Section(
                    title: Strings.openSection,
                    count: state.items.where((i) => i.status == 'open').length,
                  ),
                  for (final item in state.items.where(
                    (i) => i.status == 'open',
                  ))
                    _Row(item: item),
                ],
                if (state.items.any((i) => i.status == 'closed')) ...[
                  _Section(
                    title: Strings.closedSection,
                    count: state.items
                        .where((i) => i.status == 'closed')
                        .length,
                  ),
                  for (final item in state.items.where(
                    (i) => i.status == 'closed',
                  ))
                    _Row(item: item),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.count});

  final String title;
  final int count;

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
              color: AppColors.alertAmber,
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

class _Row extends StatefulWidget {
  const _Row({required this.item});

  final Escalation item;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> with SingleTickerProviderStateMixin {
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
    final isOpen = item.status == 'open';
    final name = Strings.customerLabel(item.customerName, item.senderId);
    final time = Strings.relativeTime(item.escalatedAt);
    final channel = item.platform == 'whatsapp'
        ? Strings.whatsapp
        : Strings.facebook;
    final under15 = DateTime.now().difference(item.escalatedAt).inMinutes < 15;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '$name, $channel, ${item.reason}, $time, '
          '${isOpen ? Strings.open : Strings.closed}',
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
                color: context.scheme.surfaceContainer,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
                border: isOpen
                    ? BorderDirectional(
                        start: BorderSide(
                          color: AppColors.alertAmber,
                          width: 4,
                        ),
                      )
                    : Border.all(
                        color: context.scheme.outlineVariant,
                        width: 1,
                      ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.innerCardPadding,
                  AppSpacing.vertical12,
                  AppSpacing.innerCardPadding,
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
                          backgroundColor: context.scheme.primaryContainer,
                          child: Text(
                            _initials(name),
                            style: context.theme.textTheme.bodyMedium?.copyWith(
                              color: context.scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isOpen)
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
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
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isOpen
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isOpen
                                      ? context.scheme.onSurface
                                      : context.scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.textTheme.bodyMedium?.copyWith(
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: under15 && isOpen
                                ? AppColors.alertAmber
                                : context.scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.bubble),
                            ),
                          ),
                          child: Text(
                            time,
                            style: context.theme.textTheme.labelSmall?.copyWith(
                              color: under15 && isOpen
                                  ? Colors.black
                                  : context.scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Future<void> _open(BuildContext context) async {
    if (_pushing) return;
    _pushing = true;
    final cubit = context.read<EscalationsCubit>();
    final sender = Uri.encodeComponent(widget.item.senderId);
    try {
      await context.push('/chat/${widget.item.platform}/$sender');
    } finally {
      _pushing = false;
    }
    if (cubit.isClosed) return;
    await cubit.load();
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
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
            Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.bubble),
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
            Icons.mark_chat_read_rounded,
            size: 40,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.vertical16),
        Text(
          Strings.noEscalations,
          style: context.theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Aucune conversation n’a été escaladée pour le moment.',
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
    final off = context.select<EscalationsCubit, bool>(
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
    final offline = context.select<EscalationsCubit, bool>(
      (c) => c.state.offline,
    );
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
            onPressed: () => context.read<EscalationsCubit>().load(),
            child: const Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}
