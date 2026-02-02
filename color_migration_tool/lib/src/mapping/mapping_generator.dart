import '../models/mapping_config.dart';
import '../models/classification.dart';
import '../analyzer/usage_analyzer.dart';

/// Generates mapping configuration templates
class MappingGenerator {
  /// Generate mapping configuration from classification results
  MappingConfig generateFromClassification(
    Map<String, ColorClassification> classifications,
    ProjectColorAnalysis analysis,
  ) {
    print('🗺️  Generating mapping template...');
    
    final strictMappings = <String, StrictMapping>{};
    final extensions = <String, ExtensionGroup>{};
    final preserved = <String>[];
    
    // Map core colors to ColorScheme (strict)
    final coreColors = classifications.values
        .where((c) => c.category == ColorCategory.core)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    int coreIndex = 0;
    for (final classification in coreColors) {
      final color = classification.color;
      final target = _suggestColorSchemeTarget(color.name, coreIndex++);
      
      strictMappings[color.qualifiedName] = StrictMapping(
        target: target,
        verifyValue: color.argbHex,
        description: color.name,
      );
    }
    
    print('  ✓ Mapped ${strictMappings.length} core colors to ColorScheme');
    
    // Group variants and component colors into extensions
    final variantColors = classifications.values
        .where((c) => c.category == ColorCategory.variant)
        .toList();
    
    final componentColors = classifications.values
        .where((c) => c.category == ColorCategory.component)
        .toList();
    
    // Create BrandColors extension for variants
    if (variantColors.isNotEmpty) {
      final brandColors = <String, ExtensionColor>{};
      
      for (final classification in variantColors) {
        final color = classification.color;
        final propertyName = _toPropertyName(color.name);
        
        brandColors[color.qualifiedName] = ExtensionColor(
          target: propertyName,
          value: color.rgbHex,
        );
      }
      
      extensions['BrandColors'] = ExtensionGroup(colors: brandColors);
      print('  ✓ Created BrandColors extension with ${brandColors.length} colors');
    }
    
    // Create ComponentColors extension
    if (componentColors.isNotEmpty) {
      final compColors = <String, ExtensionColor>{};
      
      for (final classification in componentColors) {
        final color = classification.color;
        final propertyName = _toPropertyName(color.name);
        
        compColors[color.qualifiedName] = ExtensionColor(
          target: propertyName,
          value: color.rgbHex,
        );
      }
      
      extensions['ComponentColors'] = ExtensionGroup(colors: compColors);
      print('  ✓ Created ComponentColors extension with ${compColors.length} colors');
    }
    
    // Preserve legacy and unused colors
    final legacyColors = classifications.values
        .where((c) => c.category == ColorCategory.legacy || 
                      c.category == ColorCategory.unused);
    
    for (final classification in legacyColors) {
      preserved.add(classification.color.qualifiedName);
    }
    
    if (preserved.isNotEmpty) {
      print('  ✓ Preserved ${preserved.length} legacy/unused colors');
    }
    
    return MappingConfig(
      version: '1.0',
      strictMappings: strictMappings,
      extensions: extensions,
      preserved: preserved,
      rules: MappingRules(
        requireValueMatch: true,
        blockIfMismatch: true,
        autoGenerate: true,
        groupSimilarColors: true,
      ),
    );
  }
  
  /// Suggest a ColorScheme property for a color
  String _suggestColorSchemeTarget(String colorName, int index) {
    final name = colorName.toLowerCase();
    
    // Try to match by name
    if (name.contains('primary') && !name.contains('on')) {
      return 'colorScheme.primary';
    }
    if (name.contains('secondary') || name.contains('accent')) {
      return 'colorScheme.secondary';
    }
    if (name.contains('tertiary')) {
      return 'colorScheme.tertiary';
    }
    if (name.contains('error') || name.contains('danger')) {
      return 'colorScheme.error';
    }
    if (name.contains('background') && !name.contains('on')) {
      return 'colorScheme.background';
    }
    if (name.contains('surface') && !name.contains('on')) {
      return 'colorScheme.surface';
    }
    if (name.contains('onprimary')) {
      return 'colorScheme.onPrimary';
    }
    if (name.contains('onsecondary')) {
      return 'colorScheme.onSecondary';
    }
    if (name.contains('onerror')) {
      return 'colorScheme.onError';
    }
    if (name.contains('onbackground')) {
      return 'colorScheme.onBackground';
    }
    if (name.contains('onsurface')) {
      return 'colorScheme.onSurface';
    }
    
    // Default fallback based on index
    final properties = [
      'colorScheme.primary',
      'colorScheme.secondary',
      'colorScheme.tertiary',
      'colorScheme.error',
      'colorScheme.surface',
      'colorScheme.background',
    ];
    
    return properties[index % properties.length];
  }
  
  /// Convert color name to valid Dart property name
  String _toPropertyName(String colorName) {
    // Remove class prefix (e.g., AppColors.blue50 -> blue50)
    final parts = colorName.split('.');
    final baseName = parts.last;
    
    // Convert to camelCase if needed
    return baseName[0].toLowerCase() + baseName.substring(1);
  }
}
