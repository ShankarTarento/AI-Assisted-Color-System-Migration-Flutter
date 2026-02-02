import '../models/mapping_config.dart';
import 'validation_models.dart';

/// Validates theme structure and completeness
class ThemeValidator {
  /// Essential ColorScheme properties that should be mapped
  static const Set<String> essentialColorSchemeProperties = {
    'primary',
    'onPrimary',
    'secondary',
    'onSecondary',
    'error',
    'onError',
    'surface',
    'onSurface',
    'background',
    'onBackground',
  };
  
  /// Validate theme configuration
  ThemeValidationResult validateTheme(MappingConfig config) {
    final issues = <ValidationIssue>[];
    
    // Check essential colors
    issues.addAll(_checkEssentialColors(config));
    
    // Check extensions
    issues.addAll(_checkExtensions(config));
    
    // Check naming conventions
    issues.addAll(_checkNaming(config));
    
    final errors = issues.where((i) => i.severity == ValidationSeverity.error).toList();
    
    return ThemeValidationResult(
      isValid: errors.isEmpty,
      missingEssentialColors: _getMissingEssentialColors(config),
      issues: issues,
    );
  }
  
  List<ValidationIssue> _checkEssentialColors(MappingConfig config) {
    final issues = <ValidationIssue>[];
    final missing = _getMissingEssentialColors(config);
    
    if (missing.isNotEmpty) {
      for (final property in missing) {
        issues.add(ValidationIssue(
          message: 'Missing essential ColorScheme property: $property',
          severity: property == 'error' || property == 'onError'
              ? ValidationSeverity.error
              : ValidationSeverity.warning,
          suggestion: 'Map a color to colorScheme.$property in your mapping configuration',
        ));
      }
    }
    
    return issues;
  }
  
  List<String> _getMissingEssentialColors(MappingConfig config) {
    final mappedProperties = <String>{};
    
    // Extract property names from strict mappings
    for (final mapping in config.strictMappings.values) {
      final target = mapping.target;
      if (target.startsWith('colorScheme.')) {
        final property = target.substring('colorScheme.'.length);
        mappedProperties.add(property);
      }
    }
    
    // Find missing essential properties
    return essentialColorSchemeProperties
        .where((prop) => !mappedProperties.contains(prop))
        .toList();
  }
  
  List<ValidationIssue> _checkExtensions(MappingConfig config) {
    final issues = <ValidationIssue>[];
    
    for (final entry in config.extensions.entries) {
      final extensionName = entry.key;
      final extension = entry.value;
      
      // Check extension name is valid Dart identifier
      if (!_isValidDartIdentifier(extensionName)) {
        issues.add(ValidationIssue(
          message: 'Invalid extension name: $extensionName',
          severity: ValidationSeverity.error,
          suggestion: 'Use valid Dart identifier (e.g., BrandColors, ComponentColors)',
        ));
      }
      
      // Check extension has colors
      if (extension.colors.isEmpty) {
        issues.add(ValidationIssue(
          message: 'Extension $extensionName has no colors',
          severity: ValidationSeverity.warning,
          suggestion: 'Remove empty extension or add colors',
        ));
      }
      
      // Check color property names
      for (final propertyName in extension.colors.values.map((m) => m.target)) {
        if (!_isValidDartIdentifier(propertyName)) {
          issues.add(ValidationIssue(
            message: 'Invalid property name in $extensionName: $propertyName',
            severity: ValidationSeverity.error,
            suggestion: 'Use camelCase Dart identifiers',
          ));
        }
      }
    }
    
    return issues;
  }
  
  List<ValidationIssue> _checkNaming(MappingConfig config) {
    final issues = <ValidationIssue>[];
    
    // Check for duplicate targets in strict mappings
    final targets = <String, List<String>>{};
    for (final entry in config.strictMappings.entries) {
      final colorName = entry.key;
      final target = entry.value.target;
      targets.putIfAbsent(target, () => []).add(colorName);
    }
    
    for (final entry in targets.entries) {
      if (entry.value.length > 1) {
        issues.add(ValidationIssue(
          message: 'Multiple colors mapped to same target: ${entry.key}',
          severity: ValidationSeverity.warning,
          suggestion: 'Colors: ${entry.value.join(", ")}. Consider using different targets.',
        ));
      }
    }
    
    return issues;
  }
  
  bool _isValidDartIdentifier(String name) {
    // Must start with letter or underscore
    if (name.isEmpty || (!RegExp(r'^[a-zA-Z_]').hasMatch(name))) {
      return false;
    }
    
    // Must contain only letters, digits, and underscores
    return RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name);
  }
}

/// Theme validation result
class ThemeValidationResult {
  final bool isValid;
  final List<String> missingEssentialColors;
  final List<ValidationIssue> issues;
  
  ThemeValidationResult({
    required this.isValid,
    required this.missingEssentialColors,
    required this.issues,
  });
  
  void printReport() {
    if (isValid && issues.isEmpty) {
      print('✅ Theme structure is valid');
      return;
    }
    
    print('\n🎨 Theme Validation:');
    
    if (missingEssentialColors.isNotEmpty) {
      print('\n⚠️  Missing Essential Properties:');
      for (final property in missingEssentialColors) {
        print('   • colorScheme.$property');
      }
    }
    
    for (final issue in issues) {
      issue.printIssue();
    }
  }
}
