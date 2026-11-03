import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Small `FB` / `WA` label for the customer's channel.
class ChannelChip extends StatelessWidget {
  const new(this.platform, {super.key});

  /// `facebook` or `whatsapp`.
  final String platform;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
