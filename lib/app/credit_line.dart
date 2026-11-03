import 'package:cm_app/app/strings.dart';
import 'package:cm_app/app/theme.dart';
import 'package:material_ui/material_ui.dart';

/// "Développé par" + Microzed logo. The logo is 200 px wide: keep
/// [logoHeight] at 72 dp or less.
class CreditLine extends StatelessWidget {
  const new({required this.logoHeight, super.key});

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Strings.developedByMicrozed,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Strings.developedBy,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Image.asset('assets/logo/microzed.jpeg', height: logoHeight),
        ],
      ),
    );
  }
}
