import '../analyzer/color_parser.dart' show Color;

/// Represents a color constant definition in the codebase
class ColorDefinition {
  /// The name of the color constant (e.g., "primaryBlue")
  final String name;
  
  /// The fully qualified name (e.g., "AppColors.primaryBlue")
  final String qualifiedName;
  
  /// The actual color value
  final Color value;
  
  /// The original code representation
  final String originalCode;
  
  /// File path where this color is defined
  final String filePath;
  
  /// Line number in the file
  final int lineNumber;
  
  /// Whether this is a const definition
  final bool isConst;
  
  /// Whether this is a static definition
  final bool isStatic;

  ColorDefinition({
    required this.name,
    required this.qualifiedName,
    required this.value,
    required this.originalCode,
    required this.filePath,
    required this.lineNumber,
    this.isConst = false,
    this.isStatic = false,
  });
  
  /// Get the color as ARGB hex string (e.g., "0xFF1976D2")
  String get argbHex => '0x${value.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  
  /// Get the color as RGB hex string (e.g., "#1976D2")
  String get rgbHex => '#${value.value.toRadixString(16).substring(2).toUpperCase()}';
  
  @override
  String toString() => '$qualifiedName = $rgbHex';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorDefinition &&
          runtimeType == other.runtimeType &&
          qualifiedName == other.qualifiedName &&
          value.value == other.value.value;
  
  @override
  int get hashCode => qualifiedName.hashCode ^ value.value.hashCode;
}
