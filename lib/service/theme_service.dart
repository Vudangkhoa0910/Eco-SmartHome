import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorTheme {
  bluePurple,
  deepPurple,
  tealBlue,
  pinkPurple,
  orangeRed,
  greenBlue,
}

class ThemeColorPalette {
  final String name;
  final String description;
  final List<Color> gradientColors;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData icon;

  const ThemeColorPalette({
    required this.name,
    required this.description,
    required this.gradientColors,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.icon,
  });
}

class ThemeService {
  static const String _themeKey = 'selected_color_theme';
  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();
  
  ThemeService._();

  ColorTheme _currentTheme = ColorTheme.deepPurple; // Default to deep purple
  final ValueNotifier<ColorTheme> themeNotifier = ValueNotifier(ColorTheme.deepPurple);

  // Color palettes definition
  static const Map<ColorTheme, ThemeColorPalette> _colorPalettes = {
    ColorTheme.bluePurple: ThemeColorPalette(
      name: 'Xanh Tím Cổ Điển',
      description: 'Tông màu xanh dương và tím nhẹ nhàng',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFF3E8FF)],
      primaryColor: Color(0xFF3B82F6), // Blue 500
      secondaryColor: Color(0xFF8B5CF6), // Violet 500
      accentColor: Color(0xFFF3E8FF), // Purple 50
      icon: Icons.palette,
    ),
    
    ColorTheme.deepPurple: ThemeColorPalette(
      name: 'Tím Đậm Sang Trọng',
      description: 'Tông màu tím đậm và indigo quý phái',
      gradientColors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFFDDD6FE)],
      primaryColor: Color(0xFF4C1D95), // Violet 900
      secondaryColor: Color(0xFF7C3AED), // Violet 600
      accentColor: Color(0xFFDDD6FE), // Violet 200
      icon: Icons.diamond,
    ),
    
    ColorTheme.tealBlue: ThemeColorPalette(
      name: 'Xanh Ngọc Hiện Đại',
      description: 'Tông màu xanh ngọc và xanh dương tươi mát',
      gradientColors: [Color(0xFF0F766E), Color(0xFF06B6D4), Color(0xFFCFFAFE)],
      primaryColor: Color(0xFF0F766E), // Teal 700
      secondaryColor: Color(0xFF06B6D4), // Cyan 500
      accentColor: Color(0xFFCFFAFE), // Cyan 100
      icon: Icons.water_drop,
    ),
    
    ColorTheme.pinkPurple: ThemeColorPalette(
      name: 'Hồng Tím Nữ Tính',
      description: 'Tông màu hồng và tím dịu dàng',
      gradientColors: [Color(0xFFBE185D), Color(0xFFA855F7), Color(0xFFFCE7F3)],
      primaryColor: Color(0xFFBE185D), // Pink 700
      secondaryColor: Color(0xFFA855F7), // Purple 500
      accentColor: Color(0xFFFCE7F3), // Pink 100
      icon: Icons.favorite,
    ),
    
    ColorTheme.orangeRed: ThemeColorPalette(
      name: 'Cam Đỏ Năng Động',
      description: 'Tông màu cam và đỏ sôi nổi',
      gradientColors: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFFFED7AA)],
      primaryColor: Color(0xFFDC2626), // Red 600
      secondaryColor: Color(0xFFF97316), // Orange 500
      accentColor: Color(0xFFFED7AA), // Orange 200
      icon: Icons.local_fire_department,
    ),
    
    ColorTheme.greenBlue: ThemeColorPalette(
      name: 'Xanh Lá Tự Nhiên',
      description: 'Tông màu xanh lá và xanh dương tự nhiên',
      gradientColors: [Color(0xFF059669), Color(0xFF0284C7), Color(0xFFDCFDF7)],
      primaryColor: Color(0xFF059669), // Emerald 600
      secondaryColor: Color(0xFF0284C7), // Sky 600
      accentColor: Color(0xFFDCFDF7), // Emerald 50
      icon: Icons.eco,
    ),
  };

  // Get current theme
  ColorTheme get currentTheme => _currentTheme;
  ThemeColorPalette get currentPalette => _colorPalettes[_currentTheme]!;
  
  // Get all available palettes
  Map<ColorTheme, ThemeColorPalette> get allPalettes => _colorPalettes;

  // Initialize theme from saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 1; // Default to deepPurple (index 1)
    
    if (themeIndex < ColorTheme.values.length) {
      _currentTheme = ColorTheme.values[themeIndex];
      themeNotifier.value = _currentTheme;
    }
  }

  // Change theme and save to preferences
  Future<void> changeTheme(ColorTheme newTheme) async {
    _currentTheme = newTheme;
    themeNotifier.value = newTheme;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newTheme.index);
  }

  // Get colors for specific floor based on current theme
  List<Color> getFloorGradient(String floorName) {
    final palette = currentPalette;
    
    if (floorName.contains('Sân')) {
      return [
        palette.accentColor,
        palette.secondaryColor.withOpacity(0.6),
      ];
    } else if (floorName.contains('Tầng 1')) {
      return [
        palette.secondaryColor,
        palette.primaryColor.withOpacity(0.8),
      ];
    } else if (floorName.contains('Tầng 2')) {
      return [
        palette.primaryColor,
        palette.secondaryColor,
      ];
    } else {
      return [
        palette.primaryColor.withOpacity(0.8),
        palette.secondaryColor.withOpacity(0.9),
      ];
    }
  }

  // Get room colors based on current theme
  Color getRoomColor(String roomType, String floorName) {
    final palette = currentPalette;
    
    if (floorName.contains('Sân')) {
      return palette.accentColor;
    } else if (floorName.contains('Tầng 1')) {
      return palette.secondaryColor.withOpacity(0.8);
    } else if (floorName.contains('Tầng 2')) {
      return palette.primaryColor.withOpacity(0.9);
    } else {
      return palette.primaryColor;
    }
  }

  // Get device colors based on current theme
  Color getDeviceColor(String deviceType, String roomType) {
    final palette = currentPalette;
    
    switch (deviceType.toLowerCase()) {
      case 'light':
        return palette.secondaryColor;
      case 'fan':
        return palette.primaryColor.withOpacity(0.8);
      case 'ac':
        return palette.primaryColor;
      default:
        return palette.secondaryColor.withOpacity(0.7);
    }
  }

  // Smart text color based on background brightness
  Color getAdaptiveTextColor(Color backgroundColor) {
    // Calculate luminance of background color
    double luminance = backgroundColor.computeLuminance();
    
    // If background is dark, use light text; if light, use dark text
    if (luminance > 0.5) {
      return Colors.black87; // Dark text for light backgrounds
    } else {
      return Colors.white; // Light text for dark backgrounds
    }
  }

  // Get contrast text color for floor cards
  Color getFloorTextColor(String floorName) {
    final gradientColors = getFloorGradient(floorName);
    // Use the first (primary) color to determine text color
    return getAdaptiveTextColor(gradientColors.first);
  }

  // Get icon color for floor cards (same as text but with opacity)
  Color getFloorIconColor(String floorName) {
    final textColor = getFloorTextColor(floorName);
    return textColor.withOpacity(0.9);
  }

  // Get badge background color with proper contrast
  Color getFloorBadgeColor(String floorName) {
    final textColor = getFloorTextColor(floorName);
    if (textColor == Colors.white) {
      // Dark theme - use semi-transparent white
      return Colors.white.withOpacity(0.2);
    } else {
      // Light theme - use semi-transparent black
      return Colors.black.withOpacity(0.1);
    }
  }
}
