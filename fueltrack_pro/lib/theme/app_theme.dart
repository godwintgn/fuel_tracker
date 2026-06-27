import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

/// Material 3 themes aligned with Wealth Journal (blue light / amber dark).
abstract final class AppTheme {
  static const Color primaryColor = Color(0xFF1e40af);
  static const Color secondaryColor = Color(0xFF0d9488);
  static const Color surfaceColor = Color(0xFFf4f6fa);
  static const Color onSurfaceColor = Color(0xFF111827);

  static const Color darkScaffold = Color(0xFF0f1117);
  static const Color darkSurface = Color(0xFF1a1d27);
  static const Color darkSurfaceContainerLow = Color(0xFF151821);
  static const Color darkSurfaceContainer = Color(0xFF1a1d27);
  static const Color darkSurfaceContainerHigh = Color(0xFF222631);
  static const Color darkSurfaceContainerHighest = Color(0xFF2a2d36);

  static const Color darkPrimary = Color(0xFFd97706);
  static const Color darkOnPrimary = Color(0xFF0f1117);
  static const Color darkPrimaryContainer = Color(0xFF5c3d0a);
  static const Color darkOnPrimaryContainer = Color(0xFFfef3c7);

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDDE3FF),
      onPrimaryContainer: const Color(0xFF0B1740),
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB8EBE0),
      onSecondaryContainer: const Color(0xFF004740),
      tertiary: const Color(0xFF5D4037),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFE8D6),
      onTertiaryContainer: const Color(0xFF3D2300),
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      surfaceContainerLow: const Color(0xFFf2f4f7),
      surfaceContainer: const Color(0xFFeef1f5),
      surfaceContainerHigh: const Color(0xFFe6e8eb),
      surfaceContainerHighest: const Color(0xFFe0e3e6),
      surfaceContainerLowest: Colors.white,
      error: const Color(0xFFba1a1a),
    );

    return _buildTheme(cs, scaffold: surfaceColor);
  }

  static ThemeData dark() {
    const onSurface = Color(0xFFe8eaf0);
    final cs = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: const Color(0xFF14B8A6),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF134E4A),
      onSecondaryContainer: const Color(0xFF5EEAD4),
      tertiary: const Color(0xFF34D399),
      onTertiary: Colors.white,
      surface: darkSurface,
      surfaceTint: darkPrimary,
      onSurface: onSurface,
      onSurfaceVariant: AppPalette.dark.textSecondary,
      outline: const Color(0xFF3d4454),
      outlineVariant: AppPalette.dark.cardBorder,
      surfaceContainerLowest: darkScaffold,
      surfaceContainerLow: darkSurfaceContainerLow,
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerHigh: darkSurfaceContainerHigh,
      surfaceContainerHighest: darkSurfaceContainerHighest,
    );

    return _buildTheme(cs, scaffold: darkScaffold);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, {required Color scaffold}) {
    final onSurface = colorScheme.onSurface;

    final textTheme = TextTheme(
      displayLarge: AppFonts.manropeStyle(
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      displayMedium: AppFonts.manropeStyle(
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      displaySmall: AppFonts.manropeStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineLarge: AppFonts.manropeStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: AppFonts.manropeStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineSmall: AppFonts.manropeStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: AppFonts.manropeStyle(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: AppFonts.manropeStyle(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: AppFonts.manropeStyle(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: AppFonts.interStyle(
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: AppFonts.interStyle(
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: AppFonts.interStyle(
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: AppFonts.interStyle(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: AppFonts.interStyle(
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelSmall: AppFonts.interStyle(
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      extensions: [isDark ? AppPalette.dark : AppPalette.light],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.componentPaddingX,
            vertical: AppSpacing.componentPaddingY,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.componentPaddingX,
            vertical: AppSpacing.componentPaddingY,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentPaddingX,
          vertical: AppSpacing.componentPaddingY,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 76,
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark
            ? Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.34),
                colorScheme.surfaceContainerHigh,
              )
            : colorScheme.primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppFonts.interStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontSize: 12,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
