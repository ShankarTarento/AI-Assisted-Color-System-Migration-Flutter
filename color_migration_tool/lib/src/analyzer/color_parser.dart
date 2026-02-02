/// Simple color class (compatible with Flutter Color)
class Color {
  final int value;
  
  const Color(this.value);
  
  factory Color.fromARGB(int a, int r, int g, int b) {
    return Color(((a & 0xff) << 24) |
                 ((r & 0xff) << 16) |
                 ((g & 0xff) << 8) |
                 ((b & 0xff) << 0));
  }
  
  factory Color.fromRGBO(int r, int g, int b, double opacity) {
    return Color(((((opacity * 0xff ~/ 1) & 0xff) << 24) |
                  ((r & 0xff) << 16) |
                  ((g & 0xff) << 8) |
                  ((b & 0xff) << 0)));
  }
  
  int get alpha => (0xff000000 & value) >> 24;
  int get red => (0x00ff0000 & value) >> 16;
  int get green => (0x0000ff00 & value) >> 8;
  int get blue => (0x000000ff & value) >> 0;
  
  @override
  bool operator ==(Object other) =>
      other is Color && other.value == value;
  
  @override
  int get hashCode => value.hashCode;
}

/// Parses color literals from Dart code
class ColorParser {
  /// Parse a color from various Dart formats
  /// 
  /// Supports:
  /// - Color(0xAARRGGBB)
  /// - Color.fromARGB(a, r, g, b)
  /// - Color.fromRGBO(r, g, b, opacity)
  /// - Colors.blue (if value is provided)
  Color? parseColorLiteral(String code) {
    final trimmed = code.trim();
    
    // Try Color(0x...) format
    final hexMatch = RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)').firstMatch(trimmed);
    if (hexMatch != null) {
      final hexValue = hexMatch.group(1)!;
      return Color(int.parse(hexValue, radix: 16));
    }
    
    // Try Color.fromARGB
    final argbMatch = RegExp(
      r'Color\.fromARGB\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)'
    ).firstMatch(trimmed);
    if (argbMatch != null) {
      final a = int.parse(argbMatch.group(1)!);
      final r = int.parse(argbMatch.group(2)!);
      final g = int.parse(argbMatch.group(3)!);
      final b = int.parse(argbMatch.group(4)!);
      return Color.fromARGB(a, r, g, b);
    }
    
    // Try Color.fromRGBO
    final rgboMatch = RegExp(
      r'Color\.fromRGBO\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)'
    ).firstMatch(trimmed);
    if (rgboMatch != null) {
      final r = int.parse(rgboMatch.group(1)!);
      final g = int.parse(rgboMatch.group(2)!);
      final b = int.parse(rgboMatch.group(3)!);
      final opacity = double.parse(rgboMatch.group(4)!);
      return Color.fromRGBO(r, g, b, opacity);
    }
    
    return null;
  }
  
  /// Normalize any color to ARGB hex format
  String normalizeToARGB(Color color) {
    return '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
  
  /// Convert color to RGB hex format (without alpha)
  String toRGBHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  /// Extract RGB components
  ColorComponents extractComponents(Color color) {
    return ColorComponents(
      alpha: (color.value >> 24) & 0xFF,
      red: (color.value >> 16) & 0xFF,
      green: (color.value >> 8) & 0xFF,
      blue: color.value & 0xFF,
    );
  }
  
  /// Check if two colors are equal
  bool areColorsEqual(Color a, Color b) {
    return a.value == b.value;
  }
  
  /// Extract color constant name from code
  /// e.g., "static const Color primaryBlue = Color(0xFF...)" -> "primaryBlue"
  String? extractColorName(String line) {
    // Match: static const Color <name> = ...
    final match = RegExp(
      r'static\s+const\s+Color\s+(\w+)\s*='
    ).firstMatch(line);
    
    if (match != null) {
      return match.group(1);
    }
    
    // Match: final Color <name> = ...
    final finalMatch = RegExp(
      r'final\s+Color\s+(\w+)\s*='
    ).firstMatch(line);
    
    return finalMatch?.group(1);
  }
  
  /// Extract color value from a line of code
  String? extractColorValue(String line) {
    // Find Color(...) pattern
    final colorMatch = RegExp(
      r'Color(?:\.fromARGB|\.fromRGBO)?\([^)]+\)'
    ).firstMatch(line);
    
    return colorMatch?.group(0);
  }
  
  /// Check if a line contains a color constant definition
  bool isColorDefinition(String line) {
    return (line.contains('static const Color') || 
            line.contains('final Color')) &&
           line.contains('=') &&
           (line.contains('Color(') || line.contains('Color.from'));
  }
  
  /// Check if a line contains a color usage (not definition)
  bool isColorUsage(String line) {
    return !isColorDefinition(line) && 
           (line.contains('AppColors.') || 
            line.contains('Colors.') ||
            line.contains('color:') ||
            line.contains('backgroundColor:'));
  }
}

/// RGB color components
class ColorComponents {
  final int alpha;
  final int red;
  final int green;
  final int blue;
  
  ColorComponents({
    required this.alpha,
    required this.red,
    required this.green,
    required this.blue,
  });
  
  @override
  String toString() => 'ARGB($alpha, $red, $green, $blue)';
  
  /// Get as hex string
  String toHex() => '#${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}
