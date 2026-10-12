import 'package:flutter/material.dart';

/// Palette:
///   #05668d  deep blue   – primary (light), background (dark)
///   #427aa1  steel blue  – secondary, dark surfaces/cards
///   #ebf2fa  ice white   – background (light), text on dark
///   #679436  green       – success / highlighted bar / toggle on
///   #a5be00  lime        – accent / primary buttons (dark)
class AppColors {
  AppColors._();

  // Brand palette
  static const Color deepBlue = Color(0xFF05668D);
  static const Color steelBlue = Color(0xFF427AA1);
  static const Color iceWhite = Color(0xFFEBF2FA);
  static const Color green = Color(0xFF679436);
  static const Color lime = Color(0xFFA5BE00);

  // Neutrals derived from the palette
  static const Color white = Color(0xFFFFFFFF);
  static const Color inkDark = Color(0xFF12304A); // headings on light bg
  static const Color inkMuted = Color(0xFF64798C); // subtitles / hints on light
  static const Color lightBorder = Color(0xFFD5E2EF);
  static const Color lightTint = Color(0xFFDCE8F3); // secondary button / icon chips

  // Semantic
  static const Color error = Color(0xFFD64545);

  // Habit color picker swatches (Add habit screen)
  static const List<Color> habitColors = [
    green,
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
  ];
}

class AppRadius {
  AppRadius._();
  static const double chip = 12;
  static const double field = 14;
  static const double button = 14;
  static const double card = 20;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Inter';

  // ---------------------------------------------------------------- Light
  static final ColorScheme _lightScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.deepBlue,
    onPrimary: AppColors.white,
    secondary: AppColors.steelBlue,
    onSecondary: AppColors.white,
    tertiary: AppColors.green,
    onTertiary: AppColors.white,
    error: AppColors.error,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.inkDark,
    onSurfaceVariant: AppColors.inkMuted,
    surfaceContainerHighest: AppColors.lightTint,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightBorder,
    primaryContainer: AppColors.lightTint,
    onPrimaryContainer: AppColors.deepBlue,
    secondaryContainer: Color(0xFFE3EEDB), // soft green chip bg
    onSecondaryContainer: AppColors.green,
  );

  // ----------------------------------------------------------------- Dark
  static final ColorScheme _darkScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.lime,
    onPrimary: AppColors.deepBlue,
    secondary: AppColors.iceWhite,
    onSecondary: AppColors.steelBlue,
    tertiary: AppColors.green,
    onTertiary: AppColors.white,
    error: Color(0xFFFF8A8A),
    onError: AppColors.deepBlue,
    surface: AppColors.steelBlue,
    onSurface: AppColors.iceWhite,
    onSurfaceVariant: Color(0xFFCFE0EE),
    surfaceContainerHighest: Color(0xFF5B8FB2),
    outline: Color(0xFF6C9BBA),
    outlineVariant: Color(0xFF6C9BBA),
    primaryContainer: AppColors.lime,
    onPrimaryContainer: AppColors.deepBlue,
    secondaryContainer: AppColors.lime,
    onSecondaryContainer: AppColors.deepBlue,
  );

  static ThemeData get light => _build(
    scheme: _lightScheme,
    scaffold: AppColors.iceWhite,
    fieldFill: AppColors.white,
    cardColor: AppColors.white,
    headingColor: AppColors.inkDark,
    secondaryButtonBg: AppColors.lightTint,
    secondaryButtonFg: AppColors.steelBlue,
    secondaryButtonBorder: AppColors.steelBlue,
    iconChipBg: AppColors.lightTint,
    iconChipFg: AppColors.deepBlue,
    switchOnTrack: AppColors.green,
    switchOffTrack: const Color(0xFF8A8F94),
  );

  static ThemeData get dark => _build(
    scheme: _darkScheme,
    scaffold: AppColors.deepBlue,
    fieldFill: AppColors.steelBlue,
    cardColor: AppColors.steelBlue,
    headingColor: AppColors.iceWhite,
    secondaryButtonBg: AppColors.iceWhite,
    secondaryButtonFg: AppColors.steelBlue,
    secondaryButtonBorder: AppColors.steelBlue,
    iconChipBg: AppColors.lime,
    iconChipFg: AppColors.deepBlue,
    switchOnTrack: AppColors.green,
    switchOffTrack: const Color(0xFF8A8F94),
  );

  // --------------------------------------------------------------- Builder
  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required Color fieldFill,
    required Color cardColor,
    required Color headingColor,
    required Color secondaryButtonBg,
    required Color secondaryButtonFg,
    required Color secondaryButtonBorder,
    required Color iconChipBg,
    required Color iconChipFg,
    required Color switchOnTrack,
    required Color switchOffTrack,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = _textTheme(headingColor, scheme.onSurfaceVariant);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      canvasColor: scaffold,
      dividerColor: scheme.outline.withOpacity(isDark ? 0.4 : 1),
      splashFactory: InkRipple.splashFactory,

      // App bar: transparent, left-aligned title with rounded back button
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: headingColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.sm,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: headingColor),
      ),

      // Cards / sections (Dashboard, Settings, Analytics panels)
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      // Text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: isDark
              ? AppColors.iceWhite.withOpacity(0.85)
              : AppColors.inkMuted,
        ),
        labelStyle: textTheme.labelLarge,
        border: border(isDark ? Colors.transparent : AppColors.lightBorder),
        enabledBorder:
        border(isDark ? Colors.transparent : AppColors.lightBorder),
        focusedBorder: border(isDark ? AppColors.lime : AppColors.deepBlue, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
      ),

      // Primary button: deep blue (light) / lime (dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      // Secondary button (Register on login, View Dashboard)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: secondaryButtonBg,
          foregroundColor: secondaryButtonFg,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: secondaryButtonBorder, width: 1),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      // Text links ("Log in", "See all", "Select all")
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.lime : AppColors.deepBlue,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),

      // Rounded back / icon buttons in app bar
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: headingColor,
          backgroundColor: isDark
              ? AppColors.steelBlue
              : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),

      // Switches (Dark mode, Habit reminders)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
              ? (isDark ? AppColors.lime : AppColors.white)
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
              ? switchOnTrack
              : switchOffTrack,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkboxes (Choose habits list)
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
              ? (isDark ? AppColors.lime : AppColors.green)
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(
          isDark ? AppColors.deepBlue : AppColors.white,
        ),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),

      // Chips (Daily / Done / +1 day / 82%)
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.lime : const Color(0xFFE3EEDB),
        labelStyle: textTheme.labelSmall?.copyWith(
          color: isDark ? AppColors.deepBlue : AppColors.green,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: iconChipFg,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),

      iconTheme: IconThemeData(color: scheme.onSurface),

      dividerTheme: DividerThemeData(
        color: scheme.outline.withOpacity(isDark ? 0.4 : 0.8),
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.lime : AppColors.green,
        linearTrackColor:
        isDark ? AppColors.steelBlue : AppColors.lightTint,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.labelLarge,
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardColor,
        hourMinuteColor: isDark ? AppColors.lime : AppColors.lightTint,
        hourMinuteTextColor:
        isDark ? AppColors.deepBlue : AppColors.deepBlue,
        dayPeriodColor: isDark ? AppColors.lime : AppColors.lightTint,
        dayPeriodTextColor: AppColors.deepBlue,
        dialHandColor: scheme.primary,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.iceWhite : AppColors.deepBlue,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.deepBlue : AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),

      // Custom per-app tokens (chart colors, icon chips, etc.)
      extensions: <ThemeExtension<dynamic>>[
        HabitColors(
          iconChipBackground: iconChipBg,
          iconChipForeground: iconChipFg,
          chartBar: isDark ? const Color(0xFF8FBFE0) : AppColors.steelBlue,
          chartBarHighlight: AppColors.green,
          chartGoal: AppColors.lime,
          positive: isDark ? AppColors.lime : AppColors.green,
          bannerBackground: isDark ? AppColors.steelBlue : AppColors.deepBlue,
          bannerForeground: AppColors.white,
          bannerAccent: AppColors.lime,
          logo: isDark ? AppColors.lime : AppColors.deepBlue,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ Typography
  static TextTheme _textTheme(Color heading, Color muted) {
    return TextTheme(
      // "Create Account", "Welcome back"
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: heading,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: heading,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: heading,
      ),
      // App bar titles ("Menu", "Settings", "Analytics")
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: heading,
      ),
      // Section headings ("Profile", "Recent activity")
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: heading,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: heading,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: heading,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      // Field labels, buttons
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: muted,
      ),
    );
  }
}

/// App-specific colors that don't map onto [ColorScheme].
/// Access with: `Theme.of(context).extension<HabitColors>()!`
@immutable
class HabitColors extends ThemeExtension<HabitColors> {
  const HabitColors({
    required this.iconChipBackground,
    required this.iconChipForeground,
    required this.chartBar,
    required this.chartBarHighlight,
    required this.chartGoal,
    required this.positive,
    required this.bannerBackground,
    required this.bannerForeground,
    required this.bannerAccent,
    required this.logo,
  });

  final Color iconChipBackground;
  final Color iconChipForeground;
  final Color chartBar;
  final Color chartBarHighlight;
  final Color chartGoal;
  final Color positive;
  final Color bannerBackground;
  final Color bannerForeground;
  final Color bannerAccent;
  final Color logo;

  @override
  HabitColors copyWith({
    Color? iconChipBackground,
    Color? iconChipForeground,
    Color? chartBar,
    Color? chartBarHighlight,
    Color? chartGoal,
    Color? positive,
    Color? bannerBackground,
    Color? bannerForeground,
    Color? bannerAccent,
    Color? logo,
  }) {
    return HabitColors(
      iconChipBackground: iconChipBackground ?? this.iconChipBackground,
      iconChipForeground: iconChipForeground ?? this.iconChipForeground,
      chartBar: chartBar ?? this.chartBar,
      chartBarHighlight: chartBarHighlight ?? this.chartBarHighlight,
      chartGoal: chartGoal ?? this.chartGoal,
      positive: positive ?? this.positive,
      bannerBackground: bannerBackground ?? this.bannerBackground,
      bannerForeground: bannerForeground ?? this.bannerForeground,
      bannerAccent: bannerAccent ?? this.bannerAccent,
      logo: logo ?? this.logo,
    );
  }

  @override
  HabitColors lerp(ThemeExtension<HabitColors>? other, double t) {
    if (other is! HabitColors) return this;
    return HabitColors(
      iconChipBackground:
      Color.lerp(iconChipBackground, other.iconChipBackground, t)!,
      iconChipForeground:
      Color.lerp(iconChipForeground, other.iconChipForeground, t)!,
      chartBar: Color.lerp(chartBar, other.chartBar, t)!,
      chartBarHighlight:
      Color.lerp(chartBarHighlight, other.chartBarHighlight, t)!,
      chartGoal: Color.lerp(chartGoal, other.chartGoal, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      bannerBackground:
      Color.lerp(bannerBackground, other.bannerBackground, t)!,
      bannerForeground:
      Color.lerp(bannerForeground, other.bannerForeground, t)!,
      bannerAccent: Color.lerp(bannerAccent, other.bannerAccent, t)!,
      logo: Color.lerp(logo, other.logo, t)!,
    );
  }
}