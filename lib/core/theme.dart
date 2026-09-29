import 'package:flutter/material.dart';

import '../domain/models/enums.dart';

/// CTG palette — muted greys, deep green, chocolate and maroon accents.
/// No saturated "neon" tones: everything is desaturated and works in both
/// the light and the dark theme.
class CtgColors {
  // Core
  static const green = Color(0xFF2E4A3A); // deep green (primary)
  static const greenSoft = Color(0xFF3E6B52); // lighter green for dark mode
  static const chocolate = Color(0xFF6B4A32);
  static const maroon = Color(0xFF6E2C2C);

  // Neutrals
  static const grey = Color(0xFF6E7671);
  static const greyDark = Color(0xFF3A403C);
  static const greyLight = Color(0xFFB4BAB6);

  // Surfaces
  static const lightBackground = Color(0xFFF2F3F1);
  static const lightSurface = Color(0xFFFAFAF8);
  static const darkBackground = Color(0xFF141714);
  static const darkSurface = Color(0xFF1C201D);

  static const statusColors = <TaskStatus, Color>{
    TaskStatus.backlog: grey,
    TaskStatus.todo: greyDark,
    TaskStatus.inProgress: green,
    TaskStatus.review: chocolate,
    TaskStatus.done: Color(0xFF1F5132),
    TaskStatus.blocked: maroon,
  };

  static const priorityColors = <TaskPriority, Color>{
    TaskPriority.low: grey,
    TaskPriority.medium: greenSoft,
    TaskPriority.high: chocolate,
    TaskPriority.urgent: maroon,
  };

  /// Stable, muted per-user avatar colour.
  static Color avatarColor(String seed) {
    const palette = [
      green,
      greenSoft,
      chocolate,
      maroon,
      greyDark,
      Color(0xFF4A5A50),
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash + unit) % palette.length;
    }
    return palette[hash];
  }
}

ThemeData buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;

  final scheme = isLight
      ? const ColorScheme.light(
          primary: CtgColors.green,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFDDE5DF),
          onPrimaryContainer: Color(0xFF1B2C22),
          secondary: CtgColors.chocolate,
          onSecondary: Colors.white,
          tertiary: CtgColors.maroon,
          onTertiary: Colors.white,
          error: CtgColors.maroon,
          surface: CtgColors.lightSurface,
          onSurface: Color(0xFF1E211F),
          surfaceContainerHighest: Color(0xFFE6E8E4),
          outline: CtgColors.grey,
          outlineVariant: Color(0xFFD3D7D3),
        )
      : const ColorScheme.dark(
          primary: CtgColors.greenSoft,
          onPrimary: Color(0xFF0F1A13),
          primaryContainer: Color(0xFF25382C),
          onPrimaryContainer: Color(0xFFD6E2DA),
          secondary: Color(0xFF8A6347),
          onSecondary: Color(0xFF1B120C),
          tertiary: Color(0xFF8E4141),
          onTertiary: Color(0xFF1B0E0E),
          error: Color(0xFF8E4141),
          surface: CtgColors.darkSurface,
          onSurface: Color(0xFFE2E5E1),
          surfaceContainerHighest: Color(0xFF2A2F2B),
          outline: Color(0xFF8C948E),
          outlineVariant: Color(0xFF3A403C),
        );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isLight ? CtgColors.lightBackground : CtgColors.darkBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
    chipTheme: const ChipThemeData(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withOpacity(.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
  );
}
