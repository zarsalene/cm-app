import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';

/// Small `FB` / `WA` label for the customer's channel.
class ChannelChip extends StatelessWidget {
  const ChannelChip(this.platform, {super.key});

  final String platform;

  @override
  Widget build(BuildContext context) {
    final (label, name, background, foreground) = switch (platform) {
      'facebook' => (
        'FB',
        Strings.facebook,
        AppColors.facebook,
        AppColors.onFacebook,
      ),
      'whatsapp' => (
        'WA',
        Strings.whatsapp,
        AppColors.whatsapp,
        AppColors.onWhatsapp,
      ),
      _ => (
        platform.toUpperCase(),
        platform,
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
          borderRadius: BorderRadius.circular(AppRadius.chip / 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: context.theme.textTheme.labelMedium?.copyWith(
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
