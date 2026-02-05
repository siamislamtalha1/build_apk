import 'package:flutter/material.dart';

class Default_Theme {
  // Text Styles
  static const primaryTextStyle = TextStyle(fontFamily: "Fjalla");
  static const secondoryTextStyle = TextStyle(fontFamily: "Gilroy");
  static const secondoryTextStyleMedium =
      TextStyle(fontFamily: "Gilroy", fontWeight: FontWeight.w700);
  static const tertiaryTextStyle = TextStyle(fontFamily: "CodePro");
  static const fontAwesomeRegularFont =
      TextStyle(fontFamily: "FontAwesome-Regular");
  static const fontAwesomeSolidFont =
      TextStyle(fontFamily: "FontAwesome-Solids");

  // Colors
  static Color themeColor = const Color(0xFF0A040C);
  static Color primaryColor1 = const Color(0xFFDAEAF7);
  static Color primaryColor2 = const Color.fromARGB(255, 242, 231, 240);
  static Color accentColor1 = const Color(0xFF0EA5E0);
  static Color accentColor1light = const Color(0xFF18C9ED);
  static Color accentColor2 = const Color(0xFFFE385E);
  static Color successColor = const Color(0xFF5EFF43);

  static void setBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      themeColor = const Color(0xFF0A040C);
      primaryColor1 = const Color(0xFFDAEAF7);
      primaryColor2 = const Color.fromARGB(255, 242, 231, 240);
      accentColor1 = const Color(0xFF0EA5E0);
      accentColor1light = const Color(0xFF18C9ED);
      accentColor2 = const Color(0xFFFE385E);
      successColor = const Color(0xFF5EFF43);
    } else {
      themeColor = const Color(0xFFF2F2F7);
      primaryColor1 = const Color(0xFF000000);
      primaryColor2 = const Color(0xFF3C3C43);
      accentColor1 = const Color(0xFF007AFF);
      accentColor1light = const Color(0xFF007AFF);
      accentColor2 = const Color(0xFFFF2D55);
      successColor = const Color(0xFF34C759);
    }
  }

  ThemeData get defaultThemeData {
    const darkScheme = ColorScheme.dark(
      primary: Color(0xFF0EA5E0),
      secondary: Color(0xFFFE385E),
      surface: Color(0xFF0A040C),
      surfaceContainerHighest: Color(0xFF1A111B),
      onPrimary: Color(0xFFDAEAF7),
      onSecondary: Color(0xFFDAEAF7),
      onSurface: Color(0xFFDAEAF7),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: themeColor,
      primaryColorDark: accentColor2,
      primarySwatch: MaterialColor(
        accentColor2.value,
        {
          50: accentColor2.withValues(alpha: 0.1),
          100: accentColor2.withValues(alpha: 0.2),
          200: accentColor2.withValues(alpha: 0.3),
          300: accentColor2.withValues(alpha: 0.4),
          400: accentColor2.withValues(alpha: 0.5),
          500: accentColor2.withValues(alpha: 0.6),
          600: accentColor2.withValues(alpha: 0.7),
          700: accentColor2.withValues(alpha: 0.8),
          800: accentColor2.withValues(alpha: 0.9),
          900: accentColor2,
        },
      ),
      colorScheme: darkScheme.copyWith(
        primary: accentColor1,
        secondary: accentColor2,
      ),
      iconTheme: IconThemeData(color: primaryColor1),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(accentColor2),
        interactive: true,
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: darkScheme.onSurface),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: Color(0xFFFE385E)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: darkScheme.onSurface),
        actionTextColor: darkScheme.primary,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFFFE385E),
        selectionColor: Color(0xFFFE385E),
        selectionHandleColor: Color(0xFFFE385E),
      ),
      brightness: Brightness.dark,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(primaryColor1),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor1
                : accentColor2),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor1
                : primaryColor2.withValues(alpha: 0.0)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: WidgetStatePropertyAll(TextStyle(color: darkScheme.onSurface)),
        hintStyle:
            WidgetStatePropertyAll(TextStyle(color: darkScheme.onSurface.withValues(alpha: 0.6))),
      ),

      // 🔹 Fix for white popup menus / dropdowns
      popupMenuTheme: PopupMenuThemeData(
        color: darkScheme.surfaceContainerHighest,
        textStyle: TextStyle(color: darkScheme.onSurface),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(darkScheme.surfaceContainerHighest),
        ),
        textStyle: TextStyle(color: darkScheme.onSurface),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(darkScheme.surfaceContainerHighest),
        ),
      ),

      // 🔹 Fix for cards and surfaces
      cardTheme: CardThemeData(
        color: const Color(0xFF1A111B),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: primaryColor1.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A111B),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A111B)),
    );
  }

  ThemeData get lightThemeData {
    // Premium Light Theme Colors
    const lightBackgroundColor = Color(0xFFF2F2F7); // iOS System Gray 6
    const lightSurfaceColor = Color(0xFFFFFFFF);
    const lightTextColor = Color(0xFF000000);
    const lightSecondaryTextColor = Color(0xFF3C3C43); // iOS Label Secondary
    const lightAccentColor = Color(0xFF007AFF); // iOS Blue
    const lightSecondaryColor = Color(0xFFFF2D55); // iOS Pink

    const lightScheme = ColorScheme.light(
      primary: lightAccentColor,
      secondary: lightSecondaryColor,
      surface: lightSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextColor,
      surfaceContainerHighest: Color(0xFFE5E5EA), // iOS System Gray 5
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackgroundColor,
      primaryColor: lightAccentColor,
      colorScheme: lightScheme,
      iconTheme: const IconThemeData(color: lightTextColor),
      primaryTextTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightTextColor, fontFamily: "Gilroy"),
        bodyMedium: TextStyle(color: lightTextColor, fontFamily: "Gilroy"),
        bodySmall:
            TextStyle(color: lightSecondaryTextColor, fontFamily: "Gilroy"),
        titleLarge: TextStyle(
            color: lightTextColor, fontFamily: "Fjalla", fontSize: 22),
        titleMedium: TextStyle(
            color: lightTextColor,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w600),
      ),
      // Text Theme
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightTextColor, fontFamily: "Gilroy"),
        bodyMedium: TextStyle(color: lightTextColor, fontFamily: "Gilroy"),
        bodySmall:
            TextStyle(color: lightSecondaryTextColor, fontFamily: "Gilroy"),
        titleLarge: TextStyle(
            color: lightTextColor, fontFamily: "Fjalla", fontSize: 22),
        titleMedium: TextStyle(
            color: lightTextColor,
            fontFamily: "Gilroy",
            fontWeight: FontWeight.w600),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(lightAccentColor),
        interactive: true,
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackgroundColor, // Transparent feel
        foregroundColor: lightTextColor,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: lightTextColor),
        elevation: 0,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: lightAccentColor),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: lightSurfaceColor,
        contentTextStyle: TextStyle(color: lightTextColor),
        actionTextColor: lightAccentColor,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: lightAccentColor,
        selectionColor: Color(0x4D007AFF), // lightAccentColor with alpha
        selectionHandleColor: lightAccentColor,
      ),
      brightness: Brightness.light,
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? lightAccentColor
                : const Color(0xFFE9E9EA)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      searchBarTheme: const SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(lightSurfaceColor),
        elevation: WidgetStatePropertyAll(0),
      ),
      // Popup & Menus
      popupMenuTheme: const PopupMenuThemeData(
        color: lightSurfaceColor,
        textStyle: TextStyle(color: lightTextColor),
        elevation: 4,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(lightSurfaceColor),
        ),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(lightSurfaceColor),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: lightSurfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: Color(0x1A000000),
            width: 1,
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurfaceColor,
        titleTextStyle: TextStyle(
            color: lightTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle:
            TextStyle(color: lightSecondaryTextColor, fontSize: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFC6C6C8), // iOS Separator
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: lightTextColor,
        textColor: lightTextColor,
      ),
    );
  }
}
