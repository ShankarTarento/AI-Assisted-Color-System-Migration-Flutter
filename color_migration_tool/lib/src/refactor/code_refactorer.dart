import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../models/mapping_config.dart';
import '../models/color_definition.dart';
import '../analyzer/usage_analyzer.dart';
import 'backup_manager.dart';
import 'context_analyzer.dart';
import 'refactor_validator.dart';

/// Refactors Dart code to use theme colors instead of static color constants
class CodeRefactorer {
  final MappingConfig config;
  final ProjectColorAnalysis analysis;
  
  CodeRefactorer({
    required this.config,
    required this.analysis,
  });
  
  /// Refactor all Dart files in the project
  Future<RefactorResults> refactorProject({
    required String projectPath,
    bool dryRun = true,
  }) async {
    print('🔄 ${dryRun ? "Previewing" : "Applying"} refactoring...\n');
    
    final results = RefactorResults();
    final files = await _getDartFiles(projectPath);
    
    for (final filePath in files) {
      final fileResult = await _refactorFile(filePath, dryRun: dryRun);
      
      if (fileResult.hasChanges) {
        results.addFileResult(fileResult);
        print('  ${dryRun ? "📝" : "✓"} ${_getRelativePath(filePath, projectPath)}: ${fileResult.changeCount} changes');
      }
    }
    
    print('\n📊 Refactoring Summary:');
    print('  Files scanned: ${files.length}');
    print('  Files modified: ${results.modifiedFileCount}');
    print('  Total changes: ${results.totalChangeCount}');
    
    return results;
  }
  
  /// Refactor a single file
  Future<FileRefactorResult> _refactorFile(
    String filePath, {
    required bool dryRun,
  }) async {
    final file = File(filePath);
    final originalContent = await file.readAsString();
    
    try {
      final parseResult = parseString(content: originalContent);
      
      // Find color usages and create transformations
      final visitor = ColorRefactorVisitor(
        config: config,
        analysis: analysis,
      );
      parseResult.unit.visitChildren(visitor);
      
      if (visitor.transformations.isEmpty) {
        return FileRefactorResult(
          filePath: filePath,
          originalContent: originalContent,
          modifiedContent: originalContent,
          transformations: [],
        );
      }
      
      // Apply transformations
      final modifiedContent = _applyTransformations(
        originalContent,
        visitor.transformations,
      );
      
      // Write if not dry run
      if (!dryRun) {
        await file.writeAsString(modifiedContent);
      }
      
      return FileRefactorResult(
        filePath: filePath,
        originalContent: originalContent,
        modifiedContent: modifiedContent,
        transformations: visitor.transformations,
      );
    } catch (e) {
      print('  ⚠️  Error processing $filePath: $e');
      return FileRefactorResult(
        filePath: filePath,
        originalContent: originalContent,
        modifiedContent: originalContent,
        transformations: [],
      );
    }
  }
  
  /// Apply transformations to code
  String _applyTransformations(
    String content,
    List<CodeTransformation> transformations,
  ) {
    // Sort transformations by offset (descending) to avoid offset shifts
    final sorted = List<CodeTransformation>.from(transformations)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    
    var result = content;
    
    for (final transformation in sorted) {
      result = result.substring(0, transformation.offset) +
               transformation.newCode +
               result.substring(transformation.offset + transformation.length);
    }
    
    return result;
  }
  
  /// Get all Dart files in project
  Future<List<String>> _getDartFiles(String projectPath) async {
    final files = <String>[];
    final dir = Directory(projectPath);
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Skip generated and test files
        if (!entity.path.contains('.g.dart') &&
            !entity.path.contains('test/')) {
          files.add(entity.path);
        }
      }
    }
    
    return files;
  }
  
  String _getRelativePath(String filePath, String basePath) {
    return filePath.replaceFirst('$basePath/', '');
  }
}

/// AST visitor to find and transform color usages
class ColorRefactorVisitor extends RecursiveAstVisitor<void> {
  final MappingConfig config;
  final ProjectColorAnalysis analysis;
  final List<CodeTransformation> transformations = [];
  
  ColorRefactorVisitor({
    required this.config,
    required this.analysis,
  });
  
  @override
  void visitPropertyAccess(PropertyAccess node) {
    _processColorAccess(node, node.target.toString(), node.propertyName.toString());
    super.visitPropertyAccess(node);
  }
  
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _processColorAccess(node, node.prefix.toString(), node.identifier.toString());
    super.visitPrefixedIdentifier(node);
  }
  
  void _processColorAccess(AstNode node, String prefix, String property) {
    // Check if this is a color constant access
    if (prefix != 'AppColors') return;
    
    final colorName = '$prefix.$property';
    
    // Check if this color has a mapping
    final strictMapping = config.strictMappings[colorName];
    final extensionMapping = _findExtensionMapping(colorName);
    
    if (strictMapping != null) {
      // Replace with ColorScheme access
      final newCode = _generateColorSchemeAccess(strictMapping.target);
      
      transformations.add(CodeTransformation(
        offset: node.offset,
        length: node.length,
        oldCode: node.toString(),
        newCode: newCode,
        type: TransformationType.strictMapping,
        description: 'Map to ${strictMapping.target}',
      ));
    } else if (extensionMapping != null) {
      // Replace with extension access
      final newCode = _generateExtensionAccess(
        extensionMapping.extensionName,
        extensionMapping.propertyName,
      );
      
      transformations.add(CodeTransformation(
        offset: node.offset,
        length: node.length,
        oldCode: node.toString(),
        newCode: newCode,
        type: TransformationType.extensionMapping,
        description: 'Map to ${extensionMapping.extensionName}.${extensionMapping.propertyName}',
      ));
    }
    // If no mapping, leave unchanged (preserved colors)
  }
  
  ExtensionMapping? _findExtensionMapping(String colorName) {
    for (final entry in config.extensions.entries) {
      final extName = entry.key;
      final extGroup = entry.value;
      
      if (extGroup.colors.containsKey(colorName)) {
        return ExtensionMapping(
          extensionName: extName,
          propertyName: extGroup.colors[colorName]!.target,
        );
      }
    }
    return null;
  }
  
  String _generateColorSchemeAccess(String target) {
    // target format: "colorScheme.primary"
    final parts = target.split('.');
    if (parts.length == 2 && parts[0] == 'colorScheme') {
      return 'Theme.of(context).colorScheme.${parts[1]}';
    }
    return target;
  }
  
  String _generateExtensionAccess(String extensionName, String propertyName) {
    return 'Theme.of(context).extension<$extensionName>()!.$propertyName';
  }
}

/// Represents a code transformation
class CodeTransformation {
  final int offset;
  final int length;
  final String oldCode;
  final String newCode;
  final TransformationType type;
  final String description;
  
  CodeTransformation({
    required this.offset,
    required this.length,
    required this.oldCode,
    required this.newCode,
    required this.type,
    required this.description,
  });
}

enum TransformationType {
  strictMapping,
  extensionMapping,
}

/// Extension mapping information
class ExtensionMapping {
  final String extensionName;
  final String propertyName;
  
  ExtensionMapping({
    required this.extensionName,
    required this.propertyName,
  });
}

/// Result of refactoring a single file
class FileRefactorResult {
  final String filePath;
  final String originalContent;
  final String modifiedContent;
  final List<CodeTransformation> transformations;
  
  FileRefactorResult({
    required this.filePath,
    required this.originalContent,
    required this.modifiedContent,
    required this.transformations,
  });
  
  bool get hasChanges => transformations.isNotEmpty;
  int get changeCount => transformations.length;
}

/// Overall refactoring results
class RefactorResults {
  final List<FileRefactorResult> fileResults = [];
  
  void addFileResult(FileRefactorResult result) {
    fileResults.add(result);
  }
  
  int get modifiedFileCount => fileResults.where((r) => r.hasChanges).length;
  int get totalChangeCount => fileResults.fold(0, (sum, r) => sum + r.changeCount);
}
