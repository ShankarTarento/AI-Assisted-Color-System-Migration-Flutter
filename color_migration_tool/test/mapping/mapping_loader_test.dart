import 'dart:io';
import 'package:test/test.dart';
import 'package:color_migration_tool/src/mapping/mapping_loader.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('MappingLoader', () {
    late MappingLoader loader;
    late Directory tempDir;
    
    setUp(() {
      loader = MappingLoader();
      tempDir = Directory.systemTemp.createTempSync('mapping_test_');
    });
    
    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    
    test('should load valid YAML config', () async {
      final configFile = File('${tempDir.path}/mapping.yaml');
      configFile.writeAsStringSync(createTestMappingYaml());
      
      final config = await loader.loadFromFile(configFile.path);
      
      expect(config.version, equals('1.0.0'));
      expect(config.strictMappings, isNotEmpty);
      expect(config.strictMappings.containsKey('TestColors.primary'), isTrue);
    });
    
    test('should handle missing file', () async {
      expect(
        () => loader.loadFromFile('${tempDir.path}/nonexistent.yaml'),
        throwsA(isA<FileSystemException>()),
      );
    });
    
    test('should parse strict mappings correctly', () async {
      final configFile = File('${tempDir.path}/mapping.yaml');
      configFile.writeAsStringSync(createTestMappingYaml());
      
      final config = await loader.loadFromFile(configFile.path);
      
      final mapping = config.strictMappings['TestColors.primary'];
      expect(mapping, isNotNull);
      expect(mapping!.target, equals('colorScheme.primary'));
    });
    
    test('should parse extensions correctly', () async {
      final configFile = File('${tempDir.path}/mapping.yaml');
      configFile.writeAsStringSync(createTestMappingYaml());
      
      final config = await loader.loadFromFile(configFile.path);
      
      expect(config.extensions.containsKey('BrandColors'), isTrue);
      final brandColors = config.extensions['BrandColors']!;
      expect(brandColors.colors, isNotEmpty);
    });
    
    test('should parse preserved list correctly', () async {
      final configFile = File('${tempDir.path}/mapping.yaml');
      configFile.writeAsStringSync(createTestMappingYaml());
      
      final config = await loader.loadFromFile(configFile.path);
      
      expect(config.preserved, contains('TestColors.specialColor'));
    });
    
    test('should handle malformed YAML', () async {
      final configFile = File('${tempDir.path}/bad_mapping.yaml');
      configFile.writeAsStringSync('invalid: yaml: syntax:');
      
      expect(
        () => loader.loadFromFile(configFile.path),
        throwsA(isA<Exception>()),
      );
    });
  });
}
