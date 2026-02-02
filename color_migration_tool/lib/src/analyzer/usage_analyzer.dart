import '../models/color_definition.dart';
import '../models/color_usage.dart';
import 'ast_visitor.dart';
import 'color_scanner.dart';
import 'dart:io';

/// Analyzes color usage patterns across a project
class UsageAnalyzer {
  final ColorScanner scanner = ColorScanner();
  final DartFileAnalyzer astAnalyzer = DartFileAnalyzer();
  
  /// Analyze all color usage in a project
  Future<ProjectColorAnalysis> analyzeProject(String projectPath) async {
    print('🔍 Starting project analysis...');
    
    // Step 1: Scan for all Dart files
    final dartFiles = await scanner.scanProject(projectPath);
    
    // Step 2: Extract all color definitions
    print('📊 Extracting color definitions...');
    final allDefinitions = <ColorDefinition>[];
    
    for (final filePath in dartFiles) {
      final definitions = await astAnalyzer.extractColorDefinitions(filePath);
      allDefinitions.addAll(definitions);
    }
    
    print('✓ Found ${allDefinitions.length} color definitions');
    
    // Step 3: Extract all color usages
    print('🔎 Analyzing color usages...');
    final allUsages = <ColorUsageInfo>[];
    
    for (final filePath in dartFiles) {
      final usages = await astAnalyzer.extractColorUsages(filePath);
      allUsages.addAll(usages);
    }
    
    print('✓ Found ${allUsages.length} color usages');
    
    // Step 4: Calculate usage statistics
    final stats = _calculateUsageStats(allDefinitions, allUsages);
    
    return ProjectColorAnalysis(
      totalFiles: dartFiles.length,
      colorDefinitions: allDefinitions,
      colorUsages: _convertToColorUsage(allUsages),
      usageStats: stats,
    );
  }
  
  /// Calculate usage frequency for each color
  Map<String, UsageStatistics> _calculateUsageStats(
    List<ColorDefinition> definitions,
    List<ColorUsageInfo> usages,
  ) {
    final stats = <String, UsageStatistics>{};
    
    // Initialize stats for all definitions
    for (final def in definitions) {
      stats[def.qualifiedName] = UsageStatistics(
        colorName: def.qualifiedName,
        usageCount: 0,
        fileCount: 0,
        usageLocations: [],
      );
    }
    
    // Count usages
    for (final usage in usages) {
      if (stats.containsKey(usage.colorReference)) {
        final stat = stats[usage.colorReference]!;
        stat.usageCount++;
        stat.usageLocations.add(usage.filePath);
      }
    }
    
    // Calculate file counts
    for (final stat in stats.values) {
      stat.fileCount = stat.usageLocations.toSet().length;
    }
    
    return stats;
  }
  
  /// Convert ColorUsageInfo to ColorUsage model
  List<ColorUsage> _convertToColorUsage(List<ColorUsageInfo> infos) {
    return infos.map((info) => ColorUsage(
      colorReference: info.colorReference,
      filePath: info.filePath,
      lineNumber: info.lineNumber,
      columnNumber: info.columnNumber,
      context: info.context,
      isUiContext: info.isUiContext,
    )).toList();
  }
  
  /// Get usage statistics for a specific color
  UsageStatistics? getColorStats(
    String colorName,
    Map<String, UsageStatistics> stats,
  ) {
    return stats[colorName];
  }
  
  /// Find colors with no usages (unused colors)
  List<ColorDefinition> findUnusedColors(ProjectColorAnalysis analysis) {
    final unused = <ColorDefinition>[];
    
    for (final def in analysis.colorDefinitions) {
      final stats = analysis.usageStats[def.qualifiedName];
      if (stats == null || stats.usageCount == 0) {
        unused.add(def);
      }
    }
    
    return unused;
  }
  
  /// Find colors with high usage (core colors)
  List<ColorDefinition> findCoreColors(
    ProjectColorAnalysis analysis, {
    int minUsageCount = 50,
    int minFileCount = 10,
  }) {
    final core = <ColorDefinition>[];
    
    for (final def in analysis.colorDefinitions) {
      final stats = analysis.usageStats[def.qualifiedName];
      if (stats != null && 
          stats.usageCount >= minUsageCount && 
          stats.fileCount >= minFileCount) {
        core.add(def);
      }
    }
    
    return core;
  }
  
  /// Group usages by file
  Map<String, List<ColorUsage>> groupUsagesByFile(List<ColorUsage> usages) {
    final grouped = <String, List<ColorUsage>>{};
    
    for (final usage in usages) {
      grouped.putIfAbsent(usage.filePath, () => []);
      grouped[usage.filePath]!.add(usage);
    }
    
    return grouped;
  }
  
  /// Group usages by color
  Map<String, List<ColorUsage>> groupUsagesByColor(List<ColorUsage> usages) {
    final grouped = <String, List<ColorUsage>>{};
    
    for (final usage in usages) {
      grouped.putIfAbsent(usage.colorReference, () => []);
      grouped[usage.colorReference]!.add(usage);
    }
    
    return grouped;
  }
}

/// Complete analysis results for a project
class ProjectColorAnalysis {
  final int totalFiles;
  final List<ColorDefinition> colorDefinitions;
  final List<ColorUsage> colorUsages;
  final Map<String, UsageStatistics> usageStats;
  
  ProjectColorAnalysis({
    required this.totalFiles,
    required this.colorDefinitions,
    required this.colorUsages,
    required this.usageStats,
  });
  
  /// Get sorted list of colors by usage count (descending)
  List<String> getColorsSortedByUsage() {
    final entries = usageStats.entries.toList();
    entries.sort((a, b) => b.value.usageCount.compareTo(a.value.usageCount));
    return entries.map((e) => e.key).toList();
  }
  
  /// Get total number of unique colors
  int get uniqueColorCount => colorDefinitions.length;
  
  /// Get total usage count across all colors
  int get totalUsageCount => colorUsages.length;
  
  /// Get summary statistics
  String getSummary() {
    return '''
📊 Color Analysis Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Files Scanned:    $totalFiles
Unique Colors Found:    $uniqueColorCount
Total Color Usages:     $totalUsageCount
Average Usage per Color: ${totalUsageCount ~/ (uniqueColorCount > 0 ? uniqueColorCount : 1)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }
}

/// Usage statistics for a single color
class UsageStatistics {
  final String colorName;
  int usageCount;
  int fileCount;
  final List<String> usageLocations;
  
  UsageStatistics({
    required this.colorName,
    required this.usageCount,
    required this.fileCount,
    required this.usageLocations,
  });
  
  @override
  String toString() => '$colorName: $usageCount usages across $fileCount files';
}
