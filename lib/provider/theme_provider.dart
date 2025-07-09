import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF6B73FF),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B73FF),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lexend',
        ),
        displayMedium: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lexend',
        ),
        displaySmall: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lexend',
        ),
        headlineLarge: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lexend',
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lexend',
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lexend',
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lexend',
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lexend',
        ),
        bodySmall: TextStyle(
          color: Color(0xFF718096),
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lexend',
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF6B73FF),
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6B73FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFF6B73FF)),
        hintStyle: const TextStyle(color: Color(0xFF718096)),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6B73FF),
        secondary: Color(0xFF9C88FF),
        surface: Colors.white,
        background: Color(0xFFFAFAFA),
        error: Color(0xFFE53E3E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF2D3748),
        onBackground: Color(0xFF2D3748),
        onError: Colors.white,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF6B73FF),
      scaffoldBackgroundColor: const Color(0xFF1A202C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D3748),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B73FF),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lexend',
        ),
        displayMedium: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lexend',
        ),
        displaySmall: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lexend',
        ),
        headlineLarge: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lexend',
        ),
        headlineMedium: TextStyle(
          color: Color(0xFFCBD5E0),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lexend',
        ),
        headlineSmall: TextStyle(
          color: Color(0xFFCBD5E0),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Lexend',
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 16,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lexend',
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFCBD5E0),
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lexend',
        ),
        bodySmall: TextStyle(
          color: Color(0xFFA0AEC0),
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'Lexend',
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF6B73FF),
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D3748),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6B73FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Color(0xFF6B73FF)),
        hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B73FF),
        secondary: Color(0xFF9C88FF),
        surface: Color(0xFF2D3748),
        background: Color(0xFF1A202C),
        error: Color(0xFFE53E3E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE2E8F0),
        onBackground: Color(0xFFE2E8F0),
        onError: Colors.white,
      ),
    );
  }

  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.get(_themeKey);
    if (themeValue is bool) {
      _isDarkMode = themeValue;
    } else {
      _isDarkMode = false; // Default to light mode if invalid value
    }
    notifyListeners();
  }

  void _saveThemeToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_themeKey, _isDarkMode);
  }
}
