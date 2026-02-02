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
    final report = {
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_files': analysis.totalFiles,
        'total_colors': analysis.uniqueColorCount,
        'total_usages': analysis.totalUsageCount,
      },
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
    print(analysis.getSummary());
    
    // Top 10 most used colors
    print('🔝 Top 10 Most Used Colors:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    final sortedColors = analysis.getColorsSortedByUsage().take(10);
    for (final colorName in sortedColors) {
      final stats = analysis.usageStats[colorName]!;
      print('  ${colorName.padRight(30)} → ${stats.usageCount} usages in ${stats.fileCount} files');
    }
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
  
  String _buildHtmlReport(ProjectColorAnalysis analysis) {
    final sortedColors = analysis.getColorsSortedByUsage();
    
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
  </style>
</head>
<body>
  <h1>🎨 Color Audit Report</h1>
  
  <div class="summary">
    <h2>Summary</h2>
    <p><strong>Total Files:</strong> ${analysis.totalFiles}</p>
    <p><strong>Unique Colors:</strong> ${analysis.uniqueColorCount}</p>
    <p><strong>Total Usages:</strong> ${analysis.totalUsageCount}</p>
    <p><strong>Generated:</strong> ${DateTime.now()}</p>
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
  return '''
      <tr>
        <td><div class="color-swatch" style="background-color: ${def.rgbHex}"></div></td>
        <td><strong>${def.qualifiedName}</strong></td>
        <td><code>${def.rgbHex}</code></td>
        <td><span class="usage-badge">${stats.usageCount}</span></td>
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
