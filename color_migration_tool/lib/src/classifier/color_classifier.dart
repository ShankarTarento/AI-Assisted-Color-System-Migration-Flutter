import 'dart:math' as math;
import '../models/classification.dart';
import '../models/color_definition.dart';
import '../analyzer/usage_analyzer.dart';
import '../analyzer/color_parser.dart';

/// Classifies colors based on usage patterns and characteristics
class ColorClassifier {
  // Classification thresholds (configurable)
  final int coreColorMinUsage;
  final int coreColorMinFiles;
  final int legacyColorMaxUsage;
  final double variantSimilarityThreshold;
  
  ColorClassifier({
    this.coreColorMinUsage = 10,
    this.coreColorMinFiles = 3,
    this.legacyColorMaxUsage = 5,
    this.variantSimilarityThreshold = 30.0, // Delta E threshold
  });
  
  /// Classify all colors in a project analysis
  Map<String, ColorClassification> classifyColors(
    ProjectColorAnalysis analysis,
  ) {
    final classifications = <String, ColorClassification>{};
    final coreColors = <ColorDefinition>[];
    
    print('🏷️  Classifying ${analysis.uniqueColorCount} colors...');
    
    // Step 1: Identify core colors (high usage)
    for (final def in analysis.colorDefinitions) {
      final stats = analysis.usageStats[def.qualifiedName];
      final usageCount = stats?.usageCount ?? 0;
      final fileCount = stats?.fileCount ?? 0;
      
      if (usageCount >= coreColorMinUsage && fileCount >= coreColorMinFiles) {
        coreColors.add(def);
        classifications[def.qualifiedName] = ColorClassification(
          color: def,
          category: ColorCategory.core,
          usageCount: usageCount,
          fileCount: fileCount,
          confidence: _calculateConfidence(usageCount, fileCount, 'core'),
          reason: 'High usage: $usageCount times across $fileCount files',
        );
      }
    }
    
    print('  ✓ Found ${coreColors.length} core colors');
    
    // Step 2: Identify variants (similar to core colors)
    final variants = _detectVariants(analysis.colorDefinitions, coreColors);
    for (final variant in variants) {
      final stats = analysis.usageStats[variant.color.qualifiedName];
      classifications[variant.color.qualifiedName] = variant.copyWith(
        usageCount: stats?.usageCount ?? 0,
        fileCount: stats?.fileCount ?? 0,
      );
    }
    
    print('  ✓ Found ${variants.length} variant colors');
    
    // Step 3: Identify unused colors
    int unusedCount = 0;
    for (final def in analysis.colorDefinitions) {
      if (classifications.containsKey(def.qualifiedName)) continue;
      
      final stats = analysis.usageStats[def.qualifiedName];
      final usageCount = stats?.usageCount ?? 0;
      
      if (usageCount == 0) {
        unusedCount++;
        classifications[def.qualifiedName] = ColorClassification(
          color: def,
          category: ColorCategory.unused,
          usageCount: 0,
          fileCount: 0,
          confidence: 1.0,
          reason: 'No references found in codebase',
        );
      }
    }
    
    print('  ✓ Found $unusedCount unused colors');
    
    // Step 4: Identify legacy colors (low usage)
    int legacyCount = 0;
    for (final def in analysis.colorDefinitions) {
      if (classifications.containsKey(def.qualifiedName)) continue;
      
      final stats = analysis.usageStats[def.qualifiedName];
      final usageCount = stats?.usageCount ?? 0;
      
      if (usageCount > 0 && usageCount <= legacyColorMaxUsage) {
        legacyCount++;
        classifications[def.qualifiedName] = ColorClassification(
          color: def,
          category: ColorCategory.legacy,
          usageCount: usageCount,
          fileCount: stats?.fileCount ?? 0,
          confidence: _calculateConfidence(usageCount, stats?.fileCount ?? 0, 'legacy'),
          reason: 'Low usage: $usageCount times (below threshold)',
        );
      }
    }
    
    print('  ✓ Found $legacyCount legacy colors');
    
    // Step 5: Remaining are component colors
    int componentCount = 0;
    for (final def in analysis.colorDefinitions) {
      if (classifications.containsKey(def.qualifiedName)) continue;
      
      final stats = analysis.usageStats[def.qualifiedName];
      final usageCount = stats?.usageCount ?? 0;
      final fileCount = stats?.fileCount ?? 0;
      
      componentCount++;
      classifications[def.qualifiedName] = ColorClassification(
        color: def,
        category: ColorCategory.component,
        usageCount: usageCount,
        fileCount: fileCount,
        confidence: _calculateConfidence(usageCount, fileCount, 'component'),
        reason: 'Moderate usage: $usageCount times, likely component-specific',
      );
    }
    
    print('  ✓ Found $componentCount component colors');
    
    return classifications;
  }
  
  /// Detect color variants (shades/tints of core colors)
  List<ColorClassification> _detectVariants(
    List<ColorDefinition> allColors,
    List<ColorDefinition> coreColors,
  ) {
    final variants = <ColorClassification>[];
    
    for (final color in allColors) {
      // Skip if already classified as core
      if (coreColors.any((c) => c.qualifiedName == color.qualifiedName)) {
        continue;
      }
      
      // Check similarity to each core color
      for (final coreColor in coreColors) {
        final similarity = calculateColorSimilarity(color.value, coreColor.value);
        
        // If similar enough, it's a variant
        if (similarity < variantSimilarityThreshold) {
          variants.add(ColorClassification(
            color: color,
            category: ColorCategory.variant,
            usageCount: 0, // Will be filled later
            fileCount: 0,
            confidence: 1.0 - (similarity / 100.0),
            reason: 'Variant of ${coreColor.qualifiedName} (ΔE: ${similarity.toStringAsFixed(1)})',
            parentColor: coreColor,
            similarityToParent: similarity,
          ));
          break; // Only classify as variant of first matching core color
        }
      }
      
      // Also check name patterns (e.g., blue50, blue100, etc.)
      if (variants.isEmpty || 
          !variants.any((v) => v.color.qualifiedName == color.qualifiedName)) {
        final variantByName = _detectVariantByName(color, coreColors);
        if (variantByName != null) {
          variants.add(variantByName);
        }
      }
    }
    
    return variants;
  }
  
  /// Detect variants by naming pattern
  ColorClassification? _detectVariantByName(
    ColorDefinition color,
    List<ColorDefinition> coreColors,
  ) {
    final name = color.name.toLowerCase();
    
    // Check for patterns like: blue50, blue100, primaryBlue100, etc.
    final variantPattern = RegExp(r'(\w+?)(\d{2,3})$');
    final match = variantPattern.firstMatch(name);
    
    if (match != null) {
      final baseName = match.group(1)!;
      final shade = match.group(2)!;
      
      // Find core color with similar base name
      for (final coreColor in coreColors) {
        final coreName = coreColor.name.toLowerCase();
        
        if (coreName.contains(baseName) || baseName.contains(coreName)) {
          return ColorClassification(
            color: color,
            category: ColorCategory.variant,
            usageCount: 0,
            fileCount: 0,
            confidence: 0.8, // Lower confidence for name-based detection
            reason: 'Shade variant of ${coreColor.qualifiedName} (shade: $shade)',
            parentColor: coreColor,
            similarityToParent: null,
          );
        }
      }
    }
    
    return null;
  }
  
  /// Calculate perceptual color similarity using CIEDE2000
  /// Returns Delta E value (0 = identical, 100 = very different)
  double calculateColorSimilarity(Color color1, Color color2) {
    // Convert RGB to LAB color space
    final lab1 = _rgbToLab(color1);
    final lab2 = _rgbToLab(color2);
    
    // Simplified Delta E calculation (good enough for our use case)
    final deltaL = lab1.l - lab2.l;
    final deltaA = lab1.a - lab2.a;
    final deltaB = lab1.b - lab2.b;
    
    return math.sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB);
  }
  
  /// Convert RGB to LAB color space
  LabColor _rgbToLab(Color color) {
    // RGB to XYZ
    var r = color.red / 255.0;
    var g = color.green / 255.0;
    var b = color.blue / 255.0;
    
    // Gamma correction
    r = (r > 0.04045) ? math.pow((r + 0.055) / 1.055, 2.4).toDouble() : r / 12.92;
    g = (g > 0.04045) ? math.pow((g + 0.055) / 1.055, 2.4).toDouble() : g / 12.92;
    b = (b > 0.04045) ? math.pow((b + 0.055) / 1.055, 2.4).toDouble() : b / 12.92;
    
    r *= 100;
    g *= 100;
    b *= 100;
    
    // Observer = 2°, Illuminant = D65
    final x = r * 0.4124 + g * 0.3576 + b * 0.1805;
    final y = r * 0.2126 + g * 0.7152 + b * 0.0722;
    final z = r * 0.0193 + g * 0.1192 + b * 0.9505;
    
    // XYZ to LAB
    var xRef = x / 95.047;
    var yRef = y / 100.000;
    var zRef = z / 108.883;
    
    xRef = (xRef > 0.008856) ? math.pow(xRef, 1/3).toDouble() : (7.787 * xRef) + (16/116);
    yRef = (yRef > 0.008856) ? math.pow(yRef, 1/3).toDouble() : (7.787 * yRef) + (16/116);
    zRef = (zRef > 0.008856) ? math.pow(zRef, 1/3).toDouble() : (7.787 * zRef) + (16/116);
    
    final l = (116 * yRef) - 16;
    final a = 500 * (xRef - yRef);
    final bLab = 200 * (yRef - zRef);
    
    return LabColor(l: l, a: a, b: bLab);
  }
  
  /// Calculate confidence score for classification
  double _calculateConfidence(int usageCount, int fileCount, String category) {
    switch (category) {
      case 'core':
        // High confidence for very high usage
        if (usageCount > 50 && fileCount > 10) return 1.0;
        if (usageCount > 20 && fileCount > 5) return 0.9;
        return 0.8;
      
      case 'legacy':
        // High confidence for very low usage
        if (usageCount <= 2) return 0.95;
        return 0.8;
      
      case 'component':
        // Moderate confidence (could be reclassified)
        return 0.7;
      
      default:
        return 0.5;
    }
  }
}

/// LAB color representation
class LabColor {
  final double l; // Lightness
  final double a; // Green-Red axis
  final double b; // Blue-Yellow axis
  
  LabColor({required this.l, required this.a, required this.b});
}

/// Extension to add copyWith to ColorClassification
extension ColorClassificationExtension on ColorClassification {
  ColorClassification copyWith({
    ColorDefinition? color,
    ColorCategory? category,
    int? usageCount,
    int? fileCount,
    double? confidence,
    String? reason,
    ColorDefinition? parentColor,
    double? similarityToParent,
  }) {
    return ColorClassification(
      color: color ?? this.color,
      category: category ?? this.category,
      usageCount: usageCount ?? this.usageCount,
      fileCount: fileCount ?? this.fileCount,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      parentColor: parentColor ?? this.parentColor,
      similarityToParent: similarityToParent ?? this.similarityToParent,
    );
  }
}
