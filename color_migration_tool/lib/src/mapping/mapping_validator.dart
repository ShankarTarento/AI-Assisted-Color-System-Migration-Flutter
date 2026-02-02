import '../models/mapping_config.dart';
import '../models/color_definition.dart';
import '../analyzer/color_parser.dart';
import '../analyzer/usage_analyzer.dart';

/// Validates mapping configurations
class MappingValidator {
  final ColorParser parser = ColorParser();
  
  /// Validate a mapping configuration
  ValidationResult validate(
    MappingConfig config,
    ProjectColorAnalysis analysis,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    
    print('✓ Validating mapping configuration...');
    
    // Validate strict mappings
    for (final entry in config.strictMappings.entries) {
      final colorName = entry.key;
      final mapping = entry.value;
      
      // Check if color exists in project
      final colorDef = _findColor(colorName, analysis);
      if (colorDef == null) {
        errors.add('Color not found: $colorName');
        continue;
      }
      
      // Validate target ColorScheme property
      if (!_isValidColorSchemeProperty(mapping.target)) {
        errors.add('Invalid ColorScheme property: ${mapping.target} for $colorName');
      }
      
      // Validate color value match (if specified)
      if (config.rules.requireValueMatch && mapping.verifyValue != null) {
        final expectedColor = parser.parseColorLiteral('Color(${mapping.verifyValue})');
        if (expectedColor != null && !parser.areColorsEqual(colorDef.value, expectedColor)) {
          if (config.rules.blockIfMismatch) {
            errors.add('Color value mismatch for $colorName: '
                'expected ${mapping.verifyValue}, got ${colorDef.argbHex}');
          } else {
            warnings.add('Color value mismatch for $colorName: '
                'expected ${mapping.verifyValue}, got ${colorDef.argbHex}');
          }
        }
      }
    }
    
    // Validate extensions
    for (final extEntry in config.extensions.entries) {
      final extensionName = extEntry.key;
      
      // Check valid Dart identifier
      if (!_isValidDartIdentifier(extensionName)) {
        errors.add('Invalid extension name: $extensionName (must be valid Dart identifier)');
      }
      
      // Validate extension colors
      for (final colorEntry in extEntry.value.colors.entries) {
        final colorName = colorEntry.key;
        final extColor = colorEntry.value;
        
        // Check if color exists
        final colorDef = _findColor(colorName, analysis);
        if (colorDef == null) {
          errors.add('Color not found in extension $extensionName: $colorName');
          continue;
        }
        
        // Check valid target name
        if (!_isValidDartIdentifier(extColor.target)) {
          errors.add('Invalid extension property name: ${extColor.target}');
        }
      }
    }
    
    // Check for duplicate targets
    final allTargets = <String>{};
    for (final mapping in config.strictMappings.values) {
      if (allTargets.contains(mapping.target)) {
        warnings.add('Duplicate ColorScheme target: ${mapping.target}');
      }
      allTargets.add(mapping.target);
    }
    
    // Validate preserved colors
    for (final colorName in config.preserved) {
      final colorDef = _findColor(colorName, analysis);
      if (colorDef == null) {
        warnings.add('Preserved color not found: $colorName');
      }
    }
    
    final isValid = errors.isEmpty;
    
    print(isValid 
        ? '  ✅ Validation passed'
        : '  ❌ Validation failed with ${errors.length} errors');
    
    if (warnings.isNotEmpty) {
      print('  ⚠️  ${warnings.length} warnings');
    }
    
    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Find a color definition by qualified name
  ColorDefinition? _findColor(String qualifiedName, ProjectColorAnalysis analysis) {
    return analysis.colorDefinitions
        .where((def) => def.qualifiedName == qualifiedName)
        .firstOrNull;
  }
  
  /// Check if a string is a valid ColorScheme property
  bool _isValidColorSchemeProperty(String property) {
    const validProperties = [
      'colorScheme.primary',
      'colorScheme.onPrimary',
      'colorScheme.primaryContainer',
      'colorScheme.onPrimaryContainer',
      'colorScheme.secondary',
      'colorScheme.onSecondary',
      'colorScheme.secondaryContainer',
      'colorScheme.onSecondaryContainer',
      'colorScheme.tertiary',
      'colorScheme.onTertiary',
      'colorScheme.tertiaryContainer',
      'colorScheme.onTertiaryContainer',
      'colorScheme.error',
      'colorScheme.onError',
      'colorScheme.errorContainer',
      'colorScheme.onErrorContainer',
      'colorScheme.background',
      'colorScheme.onBackground',
      'colorScheme.surface',
      'colorScheme.onSurface',
      'colorScheme.surfaceVariant',
      'colorScheme.onSurfaceVariant',
      'colorScheme.outline',
      'colorScheme.outlineVariant',
      'colorScheme.shadow',
      'colorScheme.scrim',
      'colorScheme.inverseSurface',
      'colorScheme.onInverseSurface',
      'colorScheme.inversePrimary',
    ];
    
    return validProperties.contains(property);
  }
  
  /// Check if a string is a valid Dart identifier
  bool _isValidDartIdentifier(String name) {
    final pattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return pattern.hasMatch(name);
  }
}

/// Result of mapping validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  /// Print validation results to console
  void printResults() {
    if (errors.isNotEmpty) {
      print('\n❌ Validation Errors:');
      for (final error in errors) {
        print('  • $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      print('\n⚠️  Warnings:');
      for (final warning in warnings) {
        print('  • $warning');
      }
    }
    
    if (isValid && warnings.isEmpty) {
      print('\n✅ All validations passed!');
    }
  }
}

/// Extension to add firstOrNull to Iterable
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
