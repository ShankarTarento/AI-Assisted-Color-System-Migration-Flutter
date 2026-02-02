import 'dart:io';
import '../models/mapping_config.dart';
import '../analyzer/usage_analyzer.dart';
import 'validation_models.dart';
import 'unmapped_color_detector.dart';
import 'theme_validator.dart';

/// Validates project readiness for migration
class PreMigrationValidator {
  final UnmappedColorDetector unmappedDetector = UnmappedColorDetector();
  final ThemeValidator themeValidator = ThemeValidator();
  
  /// Run all pre-migration validation checks
  Future<PreMigrationResult> validate({
    required ProjectColorAnalysis analysis,
    required MappingConfig config,
    required String projectPath,
  }) async {
    final issues = <ValidationIssue>[];
    
    print('🔍 Running pre-migration validation...\n');
    
    // 1. Check all colors are mapped
    print('Checking color mappings...');
    final unmappedColors = unmappedDetector.findUnmappedColors(
      analysis: analysis,
      config: config,
    );
    issues.addAll(_unmappedColorsToIssues(unmappedColors));
    
    // 2. Check theme completeness
    print('Checking theme structure...');
    final themeResult = themeValidator.validateTheme(config);
    issues.addAll(themeResult.issues);
    
    // 3. Check file permissions
    print('Checking file permissions...');
    issues.addAll(await _checkFilePermissions(analysis, projectPath));
    
    print('');
    
    // Categorize issues
    final errors = issues.where((i) => i.severity == ValidationSeverity.error).toList();
    final warnings = issues.where((i) => i.severity == ValidationSeverity.warning).toList();
    final info = issues.where((i) => i.severity == ValidationSeverity.info).toList();
    
    // Determine readiness
    final readiness = errors.isEmpty
        ? (warnings.isEmpty ? MigrationReadiness.ready : MigrationReadiness.readyWithWarnings)
        : MigrationReadiness.notReady;
    
    return PreMigrationResult(
      isReady: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      info: info,
      readiness: readiness,
      unmappedReport: unmappedDetector.generateReport(unmappedColors),
      themeResult: themeResult,
    );
  }
  
  List<ValidationIssue> _unmappedColorsToIssues(List<UnmappedColor> unmapped) {
    final issues = <ValidationIssue>[];
    
    for (final color in unmapped) {
      ValidationSeverity severity;
      
      switch (color.severity) {
        case UnmappedSeverity.critical:
          severity = ValidationSeverity.error;
          break;
        case UnmappedSeverity.warning:
          severity = ValidationSeverity.warning;
          break;
        case UnmappedSeverity.info:
          severity = ValidationSeverity.info;
          break;
      }
      
      issues.add(ValidationIssue(
        message: 'Unmapped color: ${color.color.name} (used ${color.usageCount} times)',
        severity: severity,
        colorName: color.color.name,
        filePath: color.usageLocations.isNotEmpty ? color.usageLocations.first : null,
        suggestion: 'Add mapping for ${color.color.name} in color_mapping.yaml',
      ));
    }
    
    return issues;
  }
  
  Future<List<ValidationIssue>> _checkFilePermissions(
    ProjectColorAnalysis analysis,
    String projectPath,
  ) async {
    final issues = <ValidationIssue>[];
    final filesToModify = <String>{};
    
    // Collect all files that will be modified
    for (final usage in analysis.colorUsages) {
      filesToModify.add(usage.filePath);
    }
    
    // Check each file is writable
    for (final filePath in filesToModify) {
      final file = File('$projectPath/$filePath');
      
      if (!await file.exists()) {
        issues.add(ValidationIssue(
          message: 'File not found: $filePath',
          severity: ValidationSeverity.error,
          filePath: filePath,
        ));
        continue;
      }
      
      // Try to check if writable (platform-specific)
      try {
        final stat = await file.stat();
        // On Unix, check write permission
        if (Platform.isLinux || Platform.isMacOS) {
          final mode = stat.mode;
          final isWritable = (mode & 0x80) != 0; // Owner write permission
          
          if (!isWritable) {
            issues.add(ValidationIssue(
              message: 'File is read-only: $filePath',
              severity: ValidationSeverity.error,
              filePath: filePath,
              suggestion: 'Change file permissions: chmod +w $filePath',
            ));
          }
        }
      } catch (e) {
        // Permission check failed, but this might be OK
        issues.add(ValidationIssue(
          message: 'Could not check permissions for: $filePath',
          severity: ValidationSeverity.warning,
          filePath: filePath,
        ));
      }
    }
    
    return issues;
  }
}

/// Result of pre-migration validation
class PreMigrationResult extends ValidationResult {
  final MigrationReadiness readiness;
  final UnmappedColorReport unmappedReport;
  final ThemeValidationResult themeResult;
  
  PreMigrationResult({
    required bool isReady,
    required List<ValidationIssue> errors,
    required List<ValidationIssue> warnings,
    required List<ValidationIssue> info,
    required this.readiness,
    required this.unmappedReport,
    required this.themeResult,
  }) : super(
          isValid: isReady,
          errors: errors,
          warnings: warnings,
          info: info,
        );
  
  void printReport() {
    print('\n' + '=' * 60);
    print('📊 Pre-Migration Validation Report');
    print('=' * 60);
    
    // Unmapped colors
    if (unmappedReport.hasUnmappedColors) {
      unmappedReport.printReport();
    } else {
      print('\n✅ All colors are mapped');
    }
    
    // Theme validation
    themeResult.printReport();
    
    // Other issues
    super.printSummary();
    
    // Readiness status
    print('\n' + '=' * 60);
    print('🎯 Migration Readiness: ${_getReadinessString()}');
    print('=' * 60);
    
    _printRecommendation();
  }
  
  String _getReadinessString() {
    switch (readiness) {
      case MigrationReadiness.ready:
        return '✅ READY';
      case MigrationReadiness.readyWithWarnings:
        return '⚠️  READY WITH WARNINGS';
      case MigrationReadiness.notReady:
        return '❌ NOT READY';
    }
  }
  
  void _printRecommendation() {
    print('\n💡 Recommendation:');
    
    switch (readiness) {
      case MigrationReadiness.ready:
        print('   • All checks passed! Safe to proceed with migration.');
        print('   • Run: dart run bin/color_migrate.dart refactor -m color_mapping.yaml --dry-run');
        break;
      
      case MigrationReadiness.readyWithWarnings:
        print('   • Migration can proceed, but review warnings first.');
        print('   • Address warnings to ensure complete migration.');
        if (unmappedReport.hasUnmappedColors) {
          print('   • ${unmappedReport.totalUnmapped} unmapped colors will remain unchanged.');
        }
        break;
      
      case MigrationReadiness.notReady:
        print('   • Fix errors before proceeding with migration.');
        if (unmappedReport.hasCriticalColors) {
          print('   • Add mappings for ${unmappedReport.criticalCount} critical colors.');
        }
        if (!themeResult.isValid) {
          print('   • Complete theme configuration with essential properties.');
        }
        break;
    }
  }
}

/// Migration readiness status
enum MigrationReadiness {
  ready,              // All checks passed
  readyWithWarnings,  // Warnings but no errors
  notReady,           // Errors present
}
