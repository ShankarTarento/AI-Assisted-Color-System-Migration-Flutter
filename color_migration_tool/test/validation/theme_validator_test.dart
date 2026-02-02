import 'package:test/test.dart';
import 'package:color_migration_tool/src/validation/theme_validator.dart';
import 'package:color_migration_tool/src/models/mapping_config.dart';

void main() {
  group('ThemeValidator', () {
    late ThemeValidator validator;
    
    setUp(() {
      validator = ThemeValidator();
    });
    
    test('should validate complete theme', () {
      final config = MappingConfig(
        version: '1.0.0',
        strictMappings: {
          'AppColors.primary': StrictMapping(target: 'colorScheme.primary'),
          'AppColors.onPrimary': StrictMapping(target: 'colorScheme.onPrimary'),
          'AppColors.secondary': StrictMapping(target: 'colorScheme.secondary'),
          'AppColors.onSecondary': StrictMapping(target: 'colorScheme.onSecondary'),
          'AppColors.error': StrictMapping(target: 'colorScheme.error'),
          'AppColors.onError': StrictMapping(target: 'colorScheme.onError'),
          'AppColors.surface': StrictMapping(target: 'colorScheme.surface'),
          'AppColors.onSurface': StrictMapping(target: 'colorScheme.onSurface'),
          'AppColors.background': StrictMapping(target: 'colorScheme.background'),
          'AppColors.onBackground': StrictMapping(target: 'colorScheme.onBackground'),
        },
        extensions: {},
        preserved: [],
        rules: MappingRules(),
      );
      
      final result = validator.validateTheme(config);
      
      expect(result.isValid, isTrue);
      expect(result.missingEssentialColors, isEmpty);
    });
    
    test('should detect missing essential properties', () {
      final config = MappingConfig(
        version: '1.0.0',
        strictMappings: {
          'AppColors.primary': StrictMapping(target: 'colorScheme.primary'),
          // Missing other essential properties
        },
        extensions: {},
        preserved: [],
        rules: MappingRules(),
      );
      
      final result = validator.validateTheme(config);
      
      expect(result.missingEssentialColors, isNotEmpty);
      expect(result.missingEssentialColors, contains('error'));
      expect(result.missingEssentialColors, contains('onError'));
    });
    
    test('should validate extension names', () {
      final config = MappingConfig(
        version: '1.0.0',
        strictMappings: {},
        extensions: {
          'Invalid-Name': ExtensionGroup(colors: {
            'AppColors.brand': ExtensionColor(target: 'blue', value: '0xFF0000FF'),
          }),
        },
        preserved: [],
        rules: MappingRules(),
      );
      
      final result = validator.validateTheme(config);
      
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) => i.message.contains('Invalid extension name')),
        isTrue,
      );
    });
    
    test('should accept valid Dart identifiers', () {
      final config = MappingConfig(
        version: '1.0.0',
        strictMappings: {},
        extensions: {
          'BrandColors': ThemeExtension(colors: {
            'AppColors.blue500': ColorMapping(target: 'blue500'),
          }),
          '_PrivateColors': ThemeExtension(colors: {
            'AppColors.internal': ColorMapping(target: 'internal'),
          }),
        },
        preserved: [],
      );
      
      final result = validator.validateTheme(config);
      
      // Should not have extension naming errors
      expect(
        result.issues.where((i) => i.message.contains('Invalid extension name')),
        isEmpty,
      );
    });
    
    test('should warn about empty extensions', () {
      final config = MappingConfig(
        version: '1.0.0',
        strictMappings: {},
        extensions: {
          'BrandColors': ThemeExtension(colors: {}),
        },
        preserved: [],
      );
      
      final result = validator.validateTheme(config);
      
      expect(
        result.issues.any((i) => i.message.contains('has no colors')),
        isTrue,
      );
    });
  });
}
