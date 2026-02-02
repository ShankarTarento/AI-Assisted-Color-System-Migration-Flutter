import 'dart:io';
import 'package:test/test.dart';
import 'package:color_migration_tool/src/analyzer/usage_analyzer.dart';
import 'package:color_migration_tool/src/classifier/color_classifier.dart';
import 'package:color_migration_tool/src/mapping/mapping_generator.dart';
import 'package:color_migration_tool/src/mapping/mapping_loader.dart';
import 'package:color_migration_tool/src/mapping/mapping_validator.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('EndToEndMigrationWorkflow', () {
    late Directory tempDir;
    late Directory tempProject;
    
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('e2e_test_');
      tempProject = createTempTestProject();
    });
    
    tearDown(() {
      cleanupTempTestProject(tempProject);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    
    test('complete audit to mapping workflow',() async {
      // Step 1: Analyze project
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(tempProject.path);
      
      expect(analysis.colorDefinitions, isNotEmpty);
      expect(analysis.totalFiles, greaterThan(0));
      
      // Step 2: Classify colors
      final classifier = ColorClassifier(analysis);
      final classification = classifier.classifyColors();
      
      expect(classification.primaryColors, isNotEmpty);
      
      // Step 3: Generate mapping template
      final generator = MappingGenerator(
        analysis: analysis,
        classification: classification,
      );
      final mappingConfig = generator.generateMapping();
      
      expect(mappingConfig.strictMappings, isNotEmpty);
      
      // Step 4: Save and reload mapping
      final mappingFile = File('${tempDir.path}/mapping.yaml');
      // Note: Would need a MappingSaver class to save, for now just test validation
      
      // Step 5: Validate mapping
      final validator = MappingValidator();
      final validationResult = validator.validate(mappingConfig, analysis);
      
      expect(validationResult.isValid, isTrue);
    });
    
    test('audit detects all colors in test project', () async {
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(tempProject.path);
      
      // Should find colors defined in test project
      expect(
        analysis.colorDefinitions.any((c) => c.name == 'primary'),
        isTrue,
      );
      expect(
        analysis.colorDefinitions.any((c) => c.name == 'secondary'),
        isTrue,
      );
      expect(
        analysis.colorDefinitions.any((c) => c.name == 'error'),
        isTrue,
      );
    });
    
    test('classifier categorizes colors correctly', () async {
      final analysis = await UsageAnalyzer().analyzeProject(tempProject.path);
      final classifier = ColorClassifier(analysis);
      final classification = classifier.classifyColors();
      
      // Primary colors should be classified
      expect(classification.primaryColors, isNotEmpty);
      
      // Test project should have some UI colors
      final totalClassified = classification.primaryColors.length +
          classification.secondaryColors.length +
          classification.semanticColors.length +
          classification.brandColors.length +
          classification.neutralColors.length;
      
      expect(totalClassified, greaterThan(0));
    });
    
    test('mapping generator creates valid config', () async {
      final analysis = await UsageAnalyzer().analyzeProject(tempProject.path);
      final classification = ColorClassifier(analysis).classifyColors();
      final generator = MappingGenerator(
        analysis: analysis,
        classification: classification,
      );
      
      final mapping = generator.generateMapping();
      
      // Should have version
      expect(mapping.version, isNotEmpty);
      
      // Should map primary colors to colorScheme
      expect(mapping.strictMappings, isNotEmpty);
      
      // May have extensions for brand colors
      // (extensions may be empty depending on classification)
    });
  });
}
