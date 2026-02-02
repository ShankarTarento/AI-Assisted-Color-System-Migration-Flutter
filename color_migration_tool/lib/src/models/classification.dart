import 'color_definition.dart';

/// Categories for color classification
enum ColorCategory {
  /// High-usage, semantic colors (map to ColorScheme)
  core,
  
  /// Shades/tints of core colors (candidates for ThemeExtension)
  variant,
  
  /// UI-specific colors (candidates for ThemeExtension)
  component,
  
  /// Rarely used or historical colors (keep unchanged)
  legacy,
  
  /// Not referenced anywhere (candidates for removal)
  unused,
}

/// Represents the classification of a color
class ColorClassification {
  /// The color definition being classified
  final ColorDefinition color;
  
  /// The assigned category
  final ColorCategory category;
  
  /// Number of times this color is used
  final int usageCount;
  
  /// Number of files where this color is used
  final int fileCount;
  
  /// Confidence score (0.0 to 1.0)
  final double confidence;
  
  /// Reason for this classification
  final String reason;
  
  /// If this is a variant, the parent core color
  final ColorDefinition? parentColor;
  
  /// Similarity score to parent color (0.0 to 1.0)
  final double? similarityToParent;

  ColorClassification({
    required this.color,
    required this.category,
    required this.usageCount,
    required this.fileCount,
    required this.confidence,
    required this.reason,
    this.parentColor,
    this.similarityToParent,
  });
  
  /// Get a human-readable category name
  String get categoryName {
    switch (category) {
      case ColorCategory.core:
        return 'Core Color';
      case ColorCategory.variant:
        return 'Variant Color';
      case ColorCategory.component:
        return 'Component Color';
      case ColorCategory.legacy:
        return 'Legacy Color';
      case ColorCategory.unused:
        return 'Unused Color';
    }
  }
  
  @override
  String toString() =>
      '${color.qualifiedName} → $categoryName (usage: $usageCount, files: $fileCount)';
}
