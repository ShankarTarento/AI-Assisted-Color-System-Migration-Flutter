/// Shared validation models for pre and post migration checks

/// Validation issue with severity and suggestion
class ValidationIssue {
  final String message;
  final ValidationSeverity severity;
  final String? filePath;
  final int? line;
  final String? suggestion;
  final String? colorName;
  
  ValidationIssue({
    required this.message,
    required this.severity,
    this.filePath,
    this.line,
    this.suggestion,
    this.colorName,
  });
  
  void printIssue() {
    final icon = _getIcon();
    final location = filePath != null 
        ? (line != null ? '$filePath:$line' : filePath!)
        : '';
    
    if (location.isNotEmpty) {
      print('$icon $location');
      print('     $message');
    } else {
      print('$icon $message');
    }
    
    if (suggestion != null) {
      print('     💡 $suggestion');
    }
  }
  
  String _getIcon() {
    switch (severity) {
      case ValidationSeverity.error:
        return '  ❌';
      case ValidationSeverity.warning:
        return '  ⚠️ ';
      case ValidationSeverity.info:
        return '  ℹ️ ';
    }
  }
}

/// Severity level for validation issues
enum ValidationSeverity {
  error,    // Blocks migration
  warning,  // Should be addressed but not blocking
  info,     // Informational only
}

/// Base validation result
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;
  final List<ValidationIssue> info;
  
  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.info = const [],
  });
  
  int get totalIssues => errors.length + warnings.length + info.length;
  
  void printSummary() {
    if (errors.isNotEmpty) {
      print('\n❌ Errors: ${errors.length}');
      for (final error in errors) {
        error.printIssue();
      }
    }
    
    if (warnings.isNotEmpty) {
      print('\n⚠️  Warnings: ${warnings.length}');
      for (final warning in warnings) {
        warning.printIssue();
      }
    }
    
    if (info.isNotEmpty) {
      print('\nℹ️  Info: ${info.length}');
      for (final item in info) {
        item.printIssue();
      }
    }
    
    if (totalIssues == 0) {
      print('\n✅ No issues found');
    }
  }
}
