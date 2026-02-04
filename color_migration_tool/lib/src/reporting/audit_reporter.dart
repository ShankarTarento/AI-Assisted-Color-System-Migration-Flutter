import 'dart:convert';
import 'dart:io';
import '../analyzer/usage_analyzer.dart';
import '../models/color_definition.dart';

/// Generates audit reports in various formats
class AuditReporter {
  /// Generate JSON audit report
  Future<void> generateJsonReport(
    ProjectColorAnalysis analysis,
    String outputPath,
  ) async {
    // Calculate used and unused colors
    final usedColors = <Map<String, dynamic>>[];
    final unusedColors = <Map<String, dynamic>>[];
    
    for (final def in analysis.colorDefinitions) {
      final stats = analysis.usageStats[def.qualifiedName];
      final usageCount = stats?.usageCount ?? 0;
      
      final colorInfo = {
        'name': def.name,
        'qualified_name': def.qualifiedName,
        'value': def.argbHex,
        'rgb_hex': def.rgbHex,
        'usage_count': usageCount,
        'file_count': stats?.fileCount ?? 0,
      };
      
      if (usageCount > 0) {
        usedColors.add(colorInfo);
      } else {
        unusedColors.add(colorInfo);
      }
    }
    
    final report = {
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_files': analysis.totalFiles,
        'total_colors': analysis.uniqueColorCount,
        'total_usages': analysis.totalUsageCount,
        'used_colors_count': usedColors.length,
        'unused_colors_count': unusedColors.length,
      },
      'used_colors': usedColors,
      'unused_colors': unusedColors,
      'color_definitions': analysis.colorDefinitions.map((def) => {
        'name': def.name,
        'qualified_name': def.qualifiedName,
        'value': def.argbHex,
        'rgb_hex': def.rgbHex,
        'file_path': def.filePath,
        'line_number': def.lineNumber,
        'is_const': def.isConst,
        'is_static': def.isStatic,
      }).toList(),
      'usage_statistics': analysis.usageStats.map((name, stats) => MapEntry(
        name,
        {
          'usage_count': stats.usageCount,
          'file_count': stats.fileCount,
          'usage_locations': stats.usageLocations,
        },
      )),
    };
    
    final file = File(outputPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    
    print('✅ JSON report saved to: $outputPath');
  }
  
  /// Generate HTML audit report
  Future<void> generateHtmlReport(
    ProjectColorAnalysis analysis,
    String outputPath,
  ) async {
    final html = _buildHtmlReport(analysis);
    
    final file = File(outputPath);
    await file.writeAsString(html);
    
    print('✅ HTML report saved to: $outputPath');
  }
  
  /// Generate CSV audit report
  Future<void> generateCsvReport(
    ProjectColorAnalysis analysis,
    String outputPath,
  ) async {
    final csv = StringBuffer();
    
    // Header
    csv.writeln('Color Name,Qualified Name,RGB Hex,Usage Count,File Count,File Path,Line Number');
    
    // Data rows
    for (final def in analysis.colorDefinitions) {
      final stats = analysis.usageStats[def.qualifiedName];
      final usageCount = stats?.usageCount ?? 0;
      final fileCount = stats?.fileCount ?? 0;
      
      csv.writeln('${def.name},${def.qualifiedName},${def.rgbHex},$usageCount,$fileCount,${def.filePath},${def.lineNumber}');
    }
    
    final file = File(outputPath);
    await file.writeAsString(csv.toString());
    
    print('✅ CSV report saved to: $outputPath');
  }
  
  /// Print console summary
  void printSummary(ProjectColorAnalysis analysis) {
    // Calculate used and unused colors
    final usedColors = analysis.colorDefinitions.where((def) {
      final stats = analysis.usageStats[def.qualifiedName];
      return stats != null && stats.usageCount > 0;
    }).toList();
    
    final unusedColors = analysis.colorDefinitions.where((def) {
      final stats = analysis.usageStats[def.qualifiedName];
      return stats == null || stats.usageCount == 0;
    }).toList();
    
    print('''
📊 Color Analysis Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Files Scanned:    ${analysis.totalFiles}
Total Colors Defined:   ${analysis.uniqueColorCount}
  ├─ Used Colors:       ${usedColors.length} (${(usedColors.length / analysis.uniqueColorCount * 100).toStringAsFixed(1)}%)
  └─ Unused Colors:     ${unusedColors.length} (${(unusedColors.length / analysis.uniqueColorCount * 100).toStringAsFixed(1)}%)
Total Color Usages:     ${analysis.totalUsageCount}
Average Usage per Color: ${analysis.totalUsageCount ~/ (analysis.uniqueColorCount > 0 ? analysis.uniqueColorCount : 1)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    
    // Top 10 most used colors
    print('🔝 Top 10 Most Used Colors:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final sortedColors = analysis.getColorsSortedByUsage().take(10);
    for (final colorName in sortedColors) {
      final stats = analysis.usageStats[colorName]!;
      if (stats.usageCount > 0) {
        print('  ${colorName.padRight(30)} → ${stats.usageCount} usages in ${stats.fileCount} files');
      }
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // Show unused colors warning if any exist
    if (unusedColors.isNotEmpty) {
      print('⚠️  ${unusedColors.length} unused colors detected (see report for details)\n');
    }
  }
  
  String _buildHtmlReport(ProjectColorAnalysis analysis) {
    final sortedColors = analysis.getColorsSortedByUsage();
    
    // Calculate used and unused colors
    final usedColors = analysis.colorDefinitions.where((def) {
      final stats = analysis.usageStats[def.qualifiedName];
      return stats != null && stats.usageCount > 0;
    }).length;
    
    final unusedColors = analysis.colorDefinitions.where((def) {
      final stats = analysis.usageStats[def.qualifiedName];
      return stats == null || stats.usageCount == 0;
    }).length;
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <title>Color Audit Report</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
      max-width: 1200px;
      margin: 40px auto;
      padding: 20px;
      background: #f5f5f5;
    }
    h1 { color: #1976D2; }
    .summary {
      background: white;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
      margin-top: 15px;
    }
    .stat-card {
      background: #f5f5f5;
      padding: 15px;
      border-radius: 6px;
      border-left: 4px solid #1976D2;
    }
    .stat-card.used {
      border-left-color: #4CAF50;
    }
    .stat-card.unused {
      border-left-color: #FF9800;
    }
    .stat-value {
      font-size: 24px;
      font-weight: bold;
      color: #1976D2;
    }
    .stat-label {
      font-size: 12px;
      color: #666;
      margin-top: 5px;
    }
    table {
      width: 100%;
      background: white;
      border-collapse: collapse;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    th {
      background: #1976D2;
      color: white;
      padding: 12px;
      text-align: left;
    }
    td {
      padding: 10px 12px;
      border-bottom: 1px solid #eee;
    }
    tr:hover { background: #f5f5f5; }
    tr.unused { opacity: 0.5; }
    .color-swatch {
      width: 40px;
      height: 40px;
      border-radius: 4px;
      border: 1px solid #ddd;
      display: inline-block;
    }
    .usage-badge {
      background: #4CAF50;
      color: white;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: bold;
    }
    .usage-badge.unused {
      background: #FF9800;
    }
  </style>
</head>
<body>
  <h1>🎨 Color Audit Report</h1>
  
  <div class="summary">
    <h2>Summary</h2>
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-value">${analysis.totalFiles}</div>
        <div class="stat-label">Total Files</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${analysis.uniqueColorCount}</div>
        <div class="stat-label">Unique Colors</div>
      </div>
      <div class="stat-card used">
        <div class="stat-value">$usedColors</div>
        <div class="stat-label">Used Colors (${(usedColors / analysis.uniqueColorCount * 100).toStringAsFixed(1)}%)</div>
      </div>
      <div class="stat-card unused">
        <div class="stat-value">$unusedColors</div>
        <div class="stat-label">Unused Colors (${(unusedColors / analysis.uniqueColorCount * 100).toStringAsFixed(1)}%)</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${analysis.totalUsageCount}</div>
        <div class="stat-label">Total Usages</div>
      </div>
    </div>
    <p style="margin-top: 15px; color: #666;"><strong>Generated:</strong> ${DateTime.now()}</p>
  </div>
  
  <h2>Color Definitions</h2>
  <table>
    <thead>
      <tr>
        <th>Color</th>
        <th>Name</th>
        <th>Value</th>
        <th>Usage</th>
        <th>Files</th>
        <th>Location</th>
      </tr>
    </thead>
    <tbody>
${sortedColors.map((colorName) {
  final def = analysis.colorDefinitions.firstWhere((d) => d.qualifiedName == colorName);
  final stats = analysis.usageStats[colorName]!;
  final isUnused = stats.usageCount == 0;
  return '''
      <tr${isUnused ? ' class="unused"' : ''}>
        <td><div class="color-swatch" style="background-color: ${def.rgbHex}"></div></td>
        <td><strong>${def.qualifiedName}</strong></td>
        <td><code>${def.rgbHex}</code></td>
        <td><span class="usage-badge${isUnused ? ' unused' : ''}">${stats.usageCount}</span></td>
        <td>${stats.fileCount}</td>
        <td><small>${def.filePath.split('/').last}:${def.lineNumber}</small></td>
      </tr>
''';
}).join()}
    </tbody>
  </table>
</body>
</html>
''';
  }
}
