import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:flutter/material.dart';

/// "Développé par" + Microzed logo with a hairline above.
class CreditLine extends StatelessWidget {
  const CreditLine({required this.logoHeight, super.key});

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: context.scheme.outlineVariant,
          indent: 0,
          endIndent: 0,
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: Strings.developedByMicrozed,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Strings.developedBy,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/logo/microzed.jpeg',
                  height: logoHeight,
                  width: logoHeight,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                Strings.microzed,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: context.scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
