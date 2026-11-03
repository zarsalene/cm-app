import 'package:material_ui/material_ui.dart';

/// Brand and channel colors. Only this file holds hex codes.
abstract class AppColors {
  static const seed = Color(0xFF0F766E);
  static const alert = Color(0xFFD97706);
  static const onAlert = Color(0xFF1C1B1F);
  static const errorLight = Color(0xFFB91C1C);
  static const onErrorLight = Color(0xFFFFFFFF);
  static const errorDark = Color(0xFFFCA5A5);
  static const onErrorDark = Color(0xFF450A0A);
  static const facebook = Color(0xFF1877F2);
  // Black, not white: white on #1877F2 is 4.23:1 and fails WCAG AA.
  static const onFacebook = Color(0xFF000000);
  static const whatsapp = Color(0xFF25D366);
  static const onWhatsapp = Color(0xFF0B3D20);
}

/// Spacing scale, multiples of a 4 dp base unit.
abstract class AppSpacing {
  static const double unit = 4;
  static const double xs = unit;
  static const double sm = 2 * unit;
  static const double md = 4 * unit;
  static const double lg = 6 * unit;
}

abstract class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed)
        .copyWith(error: AppColors.errorLight, onError: AppColors.onErrorLight),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ).copyWith(error: AppColors.errorDark, onError: AppColors.onErrorDark),
  );
}
