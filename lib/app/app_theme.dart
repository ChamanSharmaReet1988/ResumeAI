import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const _brandColor = Color(0xFFFE913E);
  static const _fontSizeIncrease = 4.0;

  static ThemeData lightTheme(TargetPlatform platform) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandColor,
      brightness: Brightness.light,
    ).copyWith(primary: _brandColor);

    return _buildTheme(
      platform: platform,
      scheme: scheme,
      scaffold: const Color(0xFFF6F7FB),
      cardColor: Colors.white,
    );
  }

  static ThemeData darkTheme(TargetPlatform platform) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandColor,
      brightness: Brightness.dark,
    ).copyWith(primary: _brandColor);

    return _buildTheme(
      platform: platform,
      scheme: scheme,
      scaffold: const Color(0xFF0E1116),
      cardColor: const Color(0xFF171C23),
    );
  }

  static ThemeData _buildTheme({
    required TargetPlatform platform,
    required ColorScheme scheme,
    required Color scaffold,
    required Color cardColor,
  }) {
    final baseTextTheme = Typography.material2021(platform: platform).black;
    final isDark = scheme.brightness == Brightness.dark;
    final iconColor = scheme.primary;
    final textTheme = _buildTextTheme(baseTextTheme, scheme);

    return ThemeData(
      useMaterial3: true,
      platform: platform,
      fontFamily: 'Nunito',
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: cardColor,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: iconColor),
      primaryIconTheme: IconThemeData(color: iconColor),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: iconColor,
        scaffoldBackgroundColor: scaffold,
        barBackgroundColor: cardColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: iconColor,
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: _bumpSize(17),
            color: scheme.onSurface,
          ),
          actionTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: _bumpSize(17),
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
          actionSmallTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: _bumpSize(15),
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: _bumpSize(9),
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: _bumpSize(17),
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: _bumpSize(34),
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: iconColor),
        actionsIconTheme: IconThemeData(color: iconColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(color: iconColor);
        }),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(
            fontSize: (textTheme.labelMedium?.fontSize ?? 16) - 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
        unselectedIconTheme: IconThemeData(color: iconColor),
        selectedIconTheme: IconThemeData(color: iconColor),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: iconColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cardColor.withValues(alpha: 0.9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          foregroundColor: isDark ? Colors.white : scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: isDark ? Colors.white : scheme.onPrimary,
          backgroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: iconColor,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        selectedColor: scheme.primaryContainer,
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardColor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cardColor,
        elevation: 2,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme scheme) {
    final themed = base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: 'Nunito',
    );

    TextStyle? outfit(TextStyle? style, FontWeight weight) {
      return style?.copyWith(
        fontFamily: 'Outfit',
        fontWeight: weight,
        color: scheme.onSurface,
      );
    }

    final withFamilies = themed.copyWith(
      displayLarge: outfit(themed.displayLarge, FontWeight.w800),
      displayMedium: outfit(themed.displayMedium, FontWeight.w800),
      displaySmall: outfit(themed.displaySmall, FontWeight.w800),
      headlineLarge: outfit(themed.headlineLarge, FontWeight.w800),
      headlineMedium: outfit(themed.headlineMedium, FontWeight.w800),
      headlineSmall: outfit(themed.headlineSmall, FontWeight.w700),
      titleLarge: outfit(themed.titleLarge, FontWeight.w700),
      titleMedium: outfit(themed.titleMedium, FontWeight.w700),
      titleSmall: outfit(themed.titleSmall, FontWeight.w700),
      labelLarge: outfit(themed.labelLarge, FontWeight.w700),
      labelMedium: outfit(themed.labelMedium, FontWeight.w600),
      labelSmall: outfit(themed.labelSmall, FontWeight.w600),
      bodyLarge: themed.bodyLarge?.copyWith(fontFamily: 'Nunito'),
      bodyMedium: themed.bodyMedium?.copyWith(fontFamily: 'Nunito'),
      bodySmall: themed.bodySmall?.copyWith(fontFamily: 'Nunito'),
    );

    return withFamilies.copyWith(
      displayLarge: _bumpTextStyle(withFamilies.displayLarge),
      displayMedium: _bumpTextStyle(withFamilies.displayMedium),
      displaySmall: _bumpTextStyle(withFamilies.displaySmall),
      headlineLarge: _bumpTextStyle(withFamilies.headlineLarge),
      headlineMedium: _bumpTextStyle(withFamilies.headlineMedium),
      headlineSmall: _bumpTextStyle(withFamilies.headlineSmall),
      titleLarge: _bumpTextStyle(withFamilies.titleLarge),
      titleMedium: _bumpTextStyle(withFamilies.titleMedium),
      titleSmall: _bumpTextStyle(withFamilies.titleSmall),
      bodyLarge: _bumpTextStyle(withFamilies.bodyLarge),
      bodyMedium: _bumpTextStyle(withFamilies.bodyMedium),
      bodySmall: _bumpTextStyle(withFamilies.bodySmall),
      labelLarge: _bumpTextStyle(withFamilies.labelLarge),
      labelMedium: _bumpTextStyle(withFamilies.labelMedium),
      labelSmall: _bumpTextStyle(withFamilies.labelSmall),
    );
  }

  static TextStyle? _bumpTextStyle(TextStyle? style) {
    if (style == null) {
      return null;
    }

    return style.copyWith(fontSize: _bumpSize(style.fontSize ?? 14));
  }

  static double _bumpSize(double base) => base + _fontSizeIncrease;
}
