import 'dart:io';
import 'code_refactorer.dart';

/// Generates diff output for refactoring changes
class DiffGenerator {
  /// Generate unified diff for a file
  String generateUnifiedDiff(FileRefactorResult result) {
    if (!result.hasChanges) return '';
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('--- ${result.filePath}');
    buffer.writeln('+++ ${result.filePath}');
    buffer.writeln('@@ Changes: ${result.changeCount} @@');
    buffer.writeln();
    
    // Show each transformation
    for (final transformation in result.transformations) {
      buffer.writeln('- ${transformation.oldCode}');
      buffer.writeln('+ ${transformation.newCode}');
      buffer.writeln('  // ${transformation.description}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  /// Generate HTML diff report
  Future<void> generateHtmlDiff(
    RefactorResults results,
    String outputPath,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('  <title>Refactoring Diff Report</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_getHtmlStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>🔄 Refactoring Diff Report</h1>');
    
    // Summary
    buffer.writeln('  <div class="summary">');
    buffer.writeln('    <h2>Summary</h2>');
    buffer.writeln('    <p><strong>Files Modified:</strong> ${results.modifiedFileCount}</p>');
    buffer.writeln('    <p><strong>Total Changes:</strong> ${results.totalChangeCount}</p>');
    buffer.writeln('    <p><strong>Generated:</strong> ${DateTime.now()}</p>');
    buffer.writeln('  </div>');
    
    // File changes
    for (final fileResult in results.fileResults) {
      if (!fileResult.hasChanges) continue;
      
      buffer.writeln('  <div class="file-diff">');
      buffer.writeln('    <h3>📄 ${fileResult.filePath}</h3>');
      buffer.writeln('    <p class="change-count">${fileResult.changeCount} changes</p>');
      
      for (final transformation in fileResult.transformations) {
        buffer.writeln('    <div class="diff-block">');
        buffer.writeln('      <div class="old-code">- ${_escapeHtml(transformation.oldCode)}</div>');
        buffer.writeln('      <div class="new-code">+ ${_escapeHtml(transformation.newCode)}</div>');
        buffer.writeln('      <div class="description">${transformation.description}</div>');
        buffer.writeln('    </div>');
      }
      
      buffer.writeln('  </div>');
    }
    
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    final file = File(outputPath);
    await file.writeAsString(buffer.toString());
    
    print('✅ HTML diff report saved to: $outputPath');
  }
  
  String _getHtmlStyles() {
    return '''
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
    .file-diff {
      background: white;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .change-count {
      color: #666;
      font-size: 14px;
    }
    .diff-block {
      margin: 15px 0;
      font-family: 'Courier New', monospace;
      font-size: 14px;
    }
    .old-code {
      background: #ffebee;
      color: #c62828;
      padding: 8px;
      border-left: 3px solid #c62828;
    }
    .new-code {
      background: #e8f5e9;
      color: #2e7d32;
      padding: 8px;
      border-left: 3px solid #2e7d32;
    }
    .description {
      color: #666;
      font-style: italic;
      padding: 4px 8px;
      font-size: 12px;
    }
    ''';
  }
  
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
