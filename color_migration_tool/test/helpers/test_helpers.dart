import 'dart:io';
import 'package:color_migration_tool/src/models/color_definition.dart';
import 'package:color_migration_tool/src/models/mapping_config.dart';
import 'package:color_migration_tool/src/analyzer/usage_analyzer.dart';

/// Test helper utilities

/// Create a test ProjectColorAnalysis with sample data
ProjectColorAnalysis createTestAnalysis({
  int fileCount = 5,
  int colorCount = 10,
  int usageCount = 50,
}) {
  final colors = <ColorDefinition>[];
  final usages = <ColorUsage>[];
  final stats = <String, UsageStatistics>{};
  
  // Create test colors
  for (var i = 0; i < colorCount; i++) {
    final colorName = 'TestColors.color$i';
    colors.add(ColorDefinition(
      name: 'color$i',
      className: 'TestColors',
      value: '0xFF${(i * 111111).toRadixString(16).padLeft(6, '0')}',
      source: 'test/fixtures/colors.dart',
      lineNumber: i + 1,
    ));
    
    // Create usages for this color
    final usageCountForColor = (usageCount / colorCount).floor();
    for (var j = 0; j < usageCountForColor; j++) {
      usages.add(ColorUsage(
        colorReference: colorName,
        filePath: 'test/fixtures/widget_$j.dart',
        lineNumber: j + 10,
        columnNumber: 20,
        context: 'color: $colorName',
      ));
    }
    
    stats[colorName] = UsageStatistics(
      colorName: colorName,
      usageCount: usageCountForColor,
      files: {'test/fixtures/widget_0.dart'},
      contexts: {'Widget'},
    );
  }
  
  return ProjectColorAnalysis(
    totalFiles: fileCount,
    colorDefinitions: colors,
    colorUsages: usages,
    usageStats: stats,
  );
}

/// Create a test MappingConfig
MappingConfig createTestMapping({
  int strictMappingCount = 5,
  int extensionCount = 1,
  int preservedCount = 2,
}) {
  final strictMappings = <String, ColorMapping>{};
  final extensions = <String, ThemeExtension>{};
  final preserved = <String>[];
  
  // Strict mappings
  for (var i = 0; i < strictMappingCount; i++) {
    strictMappings['TestColors.color$i'] = ColorMapping(
      target: i < 3 ? 'colorScheme.primary' : 'colorScheme.secondary',
    );
  }
  
  // Extensions
  if (extensionCount > 0) {
    final extColors = <String, ColorMapping>{};
    for (var i = strictMappingCount; i < strictMappingCount + 3; i++) {
      extColors['TestColors.color$i'] = ColorMapping(target: 'brandColor$i');
    }
    extensions['BrandColors'] = ThemeExtension(colors: extColors);
  }
  
  // Preserved
  for (var i = 0; i < preservedCount; i++) {
    preserved.add('TestColors.preserved$i');
  }
  
  return MappingConfig(
    version: '1.0.0',
    strictMappings: strictMappings,
    extensions: extensions,
    preserved: preserved,
  );
}

/// Create a temporary test project directory
Directory createTempTestProject() {
  final tempDir = Directory.systemTemp.createTempSync('color_migration_test_');
  
  // Create basic Flutter project structure
  Directory('${tempDir.path}/lib').createSync();
  Directory('${tempDir.path}/test').createSync();
  
  // Create colors file
  File('${tempDir.path}/lib/colors.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class TestColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
}
''');
  
  // Create widget file using colors
  File('${tempDir.path}/lib/widget.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'colors.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: TestColors.primary,
      child: Text('Test', style: TextStyle(color: TestColors.secondary)),
    );
  }
}
''');
  
  return tempDir;
}

/// Clean up temp test project
void cleanupTempTestProject(Directory tempDir) {
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}

/// Compare generated Dart code (ignoring whitespace differences)
bool compareGeneratedCode(String actual, String expected) {
  final normalizeWhitespace = (String code) =>
      code.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  return normalizeWhitespace(actual) == normalizeWhitespace(expected);
}

/// Create a minimal valid mapping YAML string
String createTestMappingYaml() {
  return '''
version: "1.0.0"

strictMappings:
  TestColors.primary:
    target: colorScheme.primary
  TestColors.secondary:
    target: colorScheme.secondary
  TestColors.error:
    target: colorScheme.error

extensions:
  BrandColors:
    colors:
      TestColors.brand1:
        target: blue500

preserved:
  - TestColors.specialColor
''';
}
