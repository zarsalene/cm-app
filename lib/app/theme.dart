import 'package:flutter/material.dart';

const _fontFamily = 'IBM Plex Sans Arabic';

abstract class AppColors {
  static const seed = Color(0xFF0D7A77);
  static const logoTeal = Color(0xFF0D7A77);
  static const logoOrange = Color(0xFFE68003);
  static const deepTeal = Color(0xFF0A4F49);
  static const alertAmber = Color(0xFFE68003);
  static const errorLight = Color(0xFFB91C1C);
  static const onErrorLight = Color(0xFFFFFFFF);
  static const errorDark = Color(0xFFFCA5A5);
  static const onErrorDark = Color(0xFF450A0A);
  static const facebook = Color(0xFF1877F2);
  static const onFacebook = Color(0xFFFFFFFF);
  static const whatsapp = Color(0xFF25D366);
  static const onWhatsapp = Color(0xFF0B3D20);

  static const Color lightPrimary = Color(0xFF0D7A77);
  static const Color darkPrimary = Color(0xFF2DB1A5);
  static const Color lightPrimaryContainer = Color(0xFFD3EEEA);
  static const Color darkPrimaryContainer = Color(0xFF0F3F3A);
  static const Color lightDeepTeal = Color(0xFF0A4F49);
  static const Color darkDeepTeal = Color(0xFF0A4F49);
  static const Color lightAccent = Color(0xFFE68003);
  static const Color darkAccent = Color(0xFFF3C06B);
  static const Color lightSecondaryContainer = Color(0xFFFBE8C8);
  static const Color darkSecondaryContainer = Color(0xFF3A2C12);
  static const Color lightSurface = Color(0xFFFAF8F3);
  static const Color darkSurface = Color(0xFF0D1412);
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color darkCardSurface = Color(0xFF151F1C);
  static const Color lightSurfaceContainerHigh = Color(0xFFF2EFE6);
  static const Color darkSurfaceContainerHigh = Color(0xFF1C2925);
  static const Color lightOutlineVariant = Color(0xFFE4DFD0);
  static const Color darkOutlineVariant = Color(0xFF2C3A35);
  static const Color lightInk = Color(0xFF1C2622);
  static const Color darkInk = Color(0xFFE7E3D8);
  static const Color lightOnSurfaceVariant = Color(0xFF5F6B66);
  static const Color darkOnSurfaceVariant = Color(0xFFA9B3AE);

  // Premium dashboard colors
  static const Color lightSurfaceDim = Color(0xFFF5F2EA);
  static const Color darkSurfaceDim = Color(0xFF111916);
  static const Color lightCardElevated = Color(0xFFFFFFFF);
  static const Color darkCardElevated = Color(0xFF1A2522);
  static const Color lightGlass = Color(0x1AFFFFFF);
  static const Color darkGlass = Color(0x1A000000);
  static const Color lightAmberGlow = Color(0x1AE68003);
  static const Color darkAmberGlow = Color(0x1AF3C06B);
  static const Color lightPrimaryGlow = Color(0x1A0D7A77);
  static const Color darkPrimaryGlow = Color(0x1A2DB1A5);
}

abstract class AppShadow {
  static const card = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 16,
    offset: Offset(0, 6),
  );
  static const elevated = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 24,
    offset: Offset(0, 10),
  );
  static const glowPrimary = BoxShadow(
    color: AppColors.lightPrimaryGlow,
    blurRadius: 20,
    offset: Offset(0, 0),
  );
  static const glowAmber = BoxShadow(
    color: AppColors.lightAmberGlow,
    blurRadius: 20,
    offset: Offset(0, 0),
  );
}

abstract class AppSpacing {
  static const double unit = 4;
  static const double xs = unit;
  static const double sm = 2 * unit;
  static const double md = 4 * unit;
  static const double lg = 6 * unit;
  static const double pageGutter = 16;
  static const double vertical8 = 8;
  static const double vertical12 = 12;
  static const double vertical16 = 16;
  static const double vertical24 = 24;
  static const double xl = 24;
  static const double innerCardPadding = 16;
  static const double dashboardPadding = 20;
}

abstract class AppRadius {
  static const double chip = 12;
  static const double button = 16;
  static const double card = 20;
  static const double hero = 28;
  static const double dialog = 28;
  static const double bottomSheetTop = 28;
  static const double snackbar = 14;
  static const double bubble = 20;
}

final class AppTheme {
  static ThemeData light() {
    final ink = AppColors.lightInk;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lightPrimaryContainer,
        onPrimaryContainer: Colors.black,
        secondary: AppColors.lightAccent,
        onSecondary: Colors.black,
        secondaryContainer: AppColors.lightSecondaryContainer,
        onSecondaryContainer: Colors.black,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightInk,
        surfaceContainer: AppColors.lightCardSurface,
        surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
        outlineVariant: AppColors.lightOutlineVariant,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        error: AppColors.errorLight,
        onError: AppColors.onErrorLight,
        surfaceTint: AppColors.lightPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightSurface,
      textTheme: _textTheme(ink),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
          side: const BorderSide(
            color: AppColors.lightOutlineVariant,
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(
            color: AppColors.lightOutlineVariant,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.lightPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(
            color: AppColors.lightOutlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.errorLight, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.errorLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.lightInk,
        elevation: 0,
        centerTitle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.dialog)),
          side: const BorderSide(
            color: AppColors.lightOutlineVariant,
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.bottomSheetTop),
            topRight: Radius.circular(AppRadius.bottomSheetTop),
          ),
          side: BorderSide(color: AppColors.lightOutlineVariant, width: 1),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.lightInk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.snackbar)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceContainerHigh,
        selectedColor: AppColors.lightPrimaryContainer,
        disabledColor: AppColors.lightOutlineVariant,
        secondarySelectedColor: AppColors.lightAccent,
        labelStyle: _plexStyle(ink, 13, FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
          side: BorderSide(color: AppColors.lightOutlineVariant, width: 1),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightOutlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    final ink = AppColors.darkInk;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: Colors.black,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.darkAccent,
        onSecondary: Colors.black,
        secondaryContainer: AppColors.darkSecondaryContainer,
        onSecondaryContainer: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkInk,
        surfaceContainer: AppColors.darkCardSurface,
        surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
        outlineVariant: AppColors.darkOutlineVariant,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        error: AppColors.errorDark,
        onError: AppColors.onErrorDark,
        surfaceTint: AppColors.darkPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkSurface,
      textTheme: _textTheme(ink),
      cardTheme: CardThemeData(
        color: AppColors.darkCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
          side: const BorderSide(color: AppColors.darkOutlineVariant, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkOutlineVariant, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.darkOutlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.errorDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
          borderSide: BorderSide(color: AppColors.errorDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkInk,
        elevation: 0,
        centerTitle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.dialog)),
          side: const BorderSide(color: AppColors.darkOutlineVariant, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.bottomSheetTop),
            topRight: Radius.circular(AppRadius.bottomSheetTop),
          ),
          side: BorderSide(color: AppColors.darkOutlineVariant, width: 1),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkInk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.snackbar)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceContainerHigh,
        selectedColor: AppColors.darkPrimaryContainer,
        disabledColor: AppColors.darkOutlineVariant,
        secondarySelectedColor: AppColors.darkAccent,
        labelStyle: _plexStyle(ink, 13, FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
          side: BorderSide(color: AppColors.darkOutlineVariant, width: 1),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(Color ink) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        height: 1.55,
        color: ink,
      ),
      bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: ink),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: ink),
      labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 11, color: ink),
      bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: ink),
    );
  }

  static TextStyle _plexStyle(Color color, double size, FontWeight weight) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
