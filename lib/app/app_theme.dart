import 'package:material_ui/material_ui.dart';

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
  });

  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;

  @override
  BrandColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? warning,
  }) =>
      BrandColors(
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  const forest = Color(0xFF176B4B);
  const parchment = Color(0xFFF4F3ED);
  const ink = Color(0xFF17211C);
  final background = dark ? const Color(0xFF101713) : parchment;
  final surface = dark ? const Color(0xFF19221D) : Colors.white;
  final foreground = dark ? const Color(0xFFF4F6F2) : ink;
  final secondary = dark ? const Color(0xFFA8B5AC) : const Color(0xFF58635C);
  final scheme = ColorScheme.fromSeed(
    seedColor: dark ? const Color(0xFF77B894) : forest,
    brightness: brightness,
    surface: surface,
  ).copyWith(
    primary: dark ? const Color(0xFF83C19C) : forest,
    onPrimary: dark ? const Color(0xFF10251A) : Colors.white,
    secondary: dark ? const Color(0xFFF2A66B) : const Color(0xFF9A4E22),
    onSecondary: dark ? const Color(0xFF281609) : Colors.white,
    surface: surface,
    onSurface: foreground,
    onSurfaceVariant: secondary,
    surfaceContainerLowest: background,
    surfaceContainerHigh:
        dark ? const Color(0xFF222D26) : const Color(0xFFEAECE5),
    outline: dark ? const Color(0xFF526359) : const Color(0xFF87938A),
    error: dark ? const Color(0xFFFF8A80) : const Color(0xFFB3261E),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    extensions: const [
      BrandColors(
        accent: Color(0xFFF2A66B),
        onAccent: Color(0xFF281609),
        success: Color(0xFF62B883),
        warning: Color(0xFFE8B14C),
      ),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: foreground,
        fontFamily: 'Barlow Condensed',
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .36)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF202A24) : const Color(0xFFF5F6F1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : secondary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 11,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .5),
      space: 1,
      thickness: 1,
    ),
  );
  final textTheme = base.textTheme.apply(
    bodyColor: foreground,
    displayColor: foreground,
    fontFamily: 'Inter',
  );
  return base.copyWith(
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontFamily: 'Barlow Condensed',
        fontSize: 42,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontFamily: 'Barlow Condensed',
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontFamily: 'Barlow Condensed',
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.45),
    ),
  );
}
