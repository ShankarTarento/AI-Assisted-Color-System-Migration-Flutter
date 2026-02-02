import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'code_refactorer.dart';
import 'context_analyzer.dart';

/// Validates refactored code before applying changes
class RefactorValidator {
  final ContextAvailabilityAnalyzer contextAnalyzer = ContextAvailabilityAnalyzer();
  
  /// Validate all refactoring changes
  ValidationResult validateChanges(RefactorResults results) {
    final errors = <ValidationIssue>[];
    final warnings = <ValidationIssue>[];
    
    for (final fileResult in results.fileResults) {
      if (!fileResult.hasChanges) continue;
      
      // Check parseability
      final parseIssues = checkParseability(fileResult);
      errors.addAll(parseIssues.where((i) => i.severity == IssueSeverity.error));
      warnings.addAll(parseIssues.where((i) => i.severity == IssueSeverity.warning));
      
      // Check imports
      final importIssues = checkImports(fileResult);
      errors.addAll(importIssues.where((i) => i.severity == IssueSeverity.error));
      warnings.addAll(importIssues.where((i) => i.severity == IssueSeverity.warning));
      
      // Check context availability
      final contextIssues = checkContextAvailability(fileResult);
      errors.addAll(contextIssues.where((i) => i.severity == IssueSeverity.error));
      warnings.addAll(contextIssues.where((i) => i.severity == IssueSeverity.warning));
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Check if modified code can be parsed
  List<ValidationIssue> checkParseability(FileRefactorResult result) {
    final issues = <ValidationIssue>[];
    
    try {
      parseString(content: result.modifiedContent);
    } catch (e) {
      issues.add(ValidationIssue(
        filePath: result.filePath,
        message: 'Modified code contains parse errors',
        severity: IssueSeverity.error,
        suggestion: 'Review the transformations for this file',
      ));
    }
    
    return issues;
  }
  
  /// Check if required imports are present
  List<ValidationIssue> checkImports(FileRefactorResult result) {
    final issues = <ValidationIssue>[];
    
    // Check if Theme.of(context) is used
    if (result.modifiedContent.contains('Theme.of(context)')) {
      // Check for Flutter material import
      if (!result.modifiedContent.contains("import 'package:flutter/material.dart'")) {
        issues.add(ValidationIssue(
          filePath: result.filePath,
          message: 'Missing Flutter material import',
          severity: IssueSeverity.warning,
          suggestion: "Add: import 'package:flutter/material.dart';",
        ));
      }
    }
    
    return issues;
  }
  
  /// Check if BuildContext is available where Theme.of(context) is used
  List<ValidationIssue> checkContextAvailability(FileRefactorResult result) {
    final issues = <ValidationIssue>[];
    
    // Parse the modified content
    try {
      final parseResult = parseString(content: result.modifiedContent);
      
      // Find all Theme.of(context) usages
      final visitor = ThemeUsageVisitor();
      parseResult.unit.visitChildren(visitor);
      
      for (final node in visitor.themeUsages) {
        final availability = contextAnalyzer.analyzeNode(node);
        
        if (availability == ContextAvailability.unavailable) {
          final reasons = contextAnalyzer.getManualInterventionReasons(node);
          
          issues.add(ValidationIssue(
            filePath: result.filePath,
            line: parseResult.lineInfo.getLocation(node.offset).lineNumber,
            message: 'BuildContext not available: ${reasons.join(", ")}',
            severity: IssueSeverity.error,
            suggestion: 'Consider using a different approach or keeping original color',
          ));
        } else if (availability == ContextAvailability.requiresManual) {
          final reasons = contextAnalyzer.getManualInterventionReasons(node);
          
          issues.add(ValidationIssue(
            filePath: result.filePath,
            line: parseResult.lineInfo.getLocation(node.offset).lineNumber,
            message: 'Manual intervention required: ${reasons.join(", ")}',
            severity: IssueSeverity.warning,
            suggestion: 'Add BuildContext parameter manually',
          ));
        }
      }
    } catch (e) {
      // Parse error already caught in checkParseability
    }
    
    return issues;
  }
}

/// Visitor to find Theme.of(context) usages
class ThemeUsageVisitor extends SimpleAstVisitor<void> {
  final List<AstNode> themeUsages = [];
  
  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check if this is Theme.of(context)
    final target = node.target;
    if (target != null && target.toString() == 'Theme') {
      if (node.methodName.name == 'of') {
        themeUsages.add(node);
      }
    }
    
    super.visitMethodInvocation(node);
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  void printResults() {
    if (errors.isNotEmpty) {
      print('\n❌ Validation Errors:');
      for (final error in errors) {
        error.printIssue();
      }
    }
    
    if (warnings.isNotEmpty) {
      print('\n⚠️  Validation Warnings:');
      for (final warning in warnings) {
        warning.printIssue();
      }
    }
    
    if (errors.isEmpty && warnings.isEmpty) {
      print('\n✅ No validation issues found');
    }
  }
}

/// Validation issue
class ValidationIssue {
  final String filePath;
  final int? line;
  final String message;
  final IssueSeverity severity;
  final String? suggestion;
  
  ValidationIssue({
    required this.filePath,
    this.line,
    required this.message,
    required this.severity,
    this.suggestion,
  });
  
  void printIssue() {
    final lineInfo = line != null ? ':$line' : '';
    final icon = severity == IssueSeverity.error ? '  ❌' : '  ⚠️ ';
    
    print('$icon $filePath$lineInfo');
    print('     $message');
    if (suggestion != null) {
      print('     💡 $suggestion');
    }
  }
}

/// Issue severity
enum IssueSeverity {
  error,
  warning,
}
