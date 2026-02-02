import '../models/color_definition.dart';
import '../models/mapping_config.dart';
import '../analyzer/usage_analyzer.dart';

/// Detects colors that are used in code but not mapped in configuration
class UnmappedColorDetector {
  /// Find all colors that don't have mappings
  List<UnmappedColor> findUnmappedColors({
    required ProjectColorAnalysis analysis,
    required MappingConfig config,
  }) {
    final unmapped = <UnmappedColor>[];
    
    for (final color in analysis.colorDefinitions) {
      final qualifiedName = color.qualifiedName;
      
      // Check if color is in any mapping category
      final isInStrictMapping = config.strictMappings.containsKey(qualifiedName);
      final isInExtension = _isInExtension(qualifiedName, config);
      final isPreserved = config.preserved.contains(qualifiedName);
      
      if (!isInStrictMapping && !isInExtension && !isPreserved) {
        final stats = analysis.usageStats[qualifiedName];
        final usageCount = stats?.usageCount ?? 0;
        final usageLocations = analysis.colorUsages
            .where((u) => u.colorReference == qualifiedName)
            .map((u) => '${u.filePath}:${u.lineNumber}')
            .toList();
        
        unmapped.add(UnmappedColor(
          color: color,
          usageCount: usageCount,
          usageLocations: usageLocations,
          severity: _categorizeSeverity(usageCount),
        ));
      }
    }
    
    // Sort by usage count (descending)
    unmapped.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    return unmapped;
  }
  
  bool _isInExtension(String colorName, MappingConfig config) {
    for (final extension in config.extensions.values) {
      if (extension.colors.containsKey(colorName)) {
        return true;
      }
    }
    return false;
  }
  
  UnmappedSeverity _categorizeSeverity(int usageCount) {
    if (usageCount >= 10) {
      return UnmappedSeverity.critical;
    } else if (usageCount >= 3) {
      return UnmappedSeverity.warning;
    } else {
      return UnmappedSeverity.info;
    }
  }
  
  /// Generate a comprehensive report of unmapped colors
  UnmappedColorReport generateReport(List<UnmappedColor> unmapped) {
    final critical = unmapped.where((u) => u.severity == UnmappedSeverity.critical).toList();
    final warnings = unmapped.where((u) => u.severity == UnmappedSeverity.warning).toList();
    final info = unmapped.where((u) => u.severity == UnmappedSeverity.info).toList();
    
    return UnmappedColorReport(
      totalUnmapped: unmapped.length,
      criticalCount: critical.length,
      warningCount: warnings.length,
      infoCount: info.length,
      criticalColors: critical,
      warningColors: warnings,
      infoColors: info,
    );
  }
}

/// Unmapped color with usage information
class UnmappedColor {
  final ColorDefinition color;
  final int usageCount;
  final List<String> usageLocations;
  final UnmappedSeverity severity;
  
  UnmappedColor({
    required this.color,
    required this.usageCount,
    required this.usageLocations,
    required this.severity,
  });
  
  String get severityIcon {
    switch (severity) {
      case UnmappedSeverity.critical:
        return '🔴';
      case UnmappedSeverity.warning:
        return '🟡';
      case UnmappedSeverity.info:
        return '🔵';
    }
  }
}

/// Severity of unmapped color based on usage
enum UnmappedSeverity {
  critical,  // High usage (>=10)
  warning,   // Medium usage (3-9)
  info,      // Low usage (<3)
}

/// Report of all unmapped colors
class UnmappedColorReport {
  final int totalUnmapped;
  final int criticalCount;
  final int warningCount;
  final int infoCount;
  final List<UnmappedColor> criticalColors;
  final List<UnmappedColor> warningColors;
  final List<UnmappedColor> infoColors;
  
  UnmappedColorReport({
    required this.totalUnmapped,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
    required this.criticalColors,
    required this.warningColors,
    required this.infoColors,
  });
  
  bool get hasUnmappedColors => totalUnmapped > 0;
  bool get hasCriticalColors => criticalCount > 0;
  
  void printReport() {
    if (!hasUnmappedColors) {
      print('✅ All colors are mapped');
      return;
    }
    
    print('\n📋 Unmapped Colors Report:');
    print('   Total: $totalUnmapped colors');
    
    if (criticalCount > 0) {
      print('\n🔴 Critical (High Usage): $criticalCount colors');
      for (final color in criticalColors) {
        print('   ${color.color.name} (${color.color.rgbHex})');
        print('     → Used ${color.usageCount} times');
        print('     → First location: ${color.usageLocations.first}');
      }
    }
    
    if (warningCount > 0) {
      print('\n🟡 Warning (Medium Usage): $warningCount colors');
      for (final color in warningColors) {
        print('   ${color.color.name} (${color.color.rgbHex}) - Used ${color.usageCount} times');
      }
    }
    
    if (infoCount > 0) {
      print('\n🔵 Info (Low Usage): $infoCount colors');
      for (final color in infoColors.take(5)) {
        print('   ${color.color.name} (${color.color.rgbHex}) - Used ${color.usageCount} times');
      }
      if (infoCount > 5) {
        print('   ... and ${infoCount - 5} more');
      }
    }
    
    print('\n💡 Recommendation:');
    if (hasCriticalColors) {
      print('   Add mappings for critical colors before migration');
    } else {
      print('   Review and add mappings for all unmapped colors');
    }
  }
}
