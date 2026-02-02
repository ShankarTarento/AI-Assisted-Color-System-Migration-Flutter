import 'dart:io';
import 'package:path/path.dart' as path;

/// Scans a Flutter project for Dart files
class ColorScanner {
  /// Scan a Flutter project directory for all Dart files
  /// 
  /// Returns a list of absolute file paths
  Future<List<String>> scanProject(String projectPath) async {
    final projectDir = Directory(projectPath);
    
    if (!await projectDir.exists()) {
      throw Exception('Project directory does not exist: $projectPath');
    }
    
    print('📂 Scanning project: $projectPath');
    
    // Scan directories recursively for .dart files
    final dartFiles = <String>[];
    
    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (_shouldIncludeFile(entity.path)) {
          dartFiles.add(path.absolute(entity.path));
        }
      }
    }
    
    print('✓ Found ${dartFiles.length} Dart files');
    return dartFiles;
  }
  
  /// Check if a file should be included in the scan
  bool _shouldIncludeFile(String filePath) {
    // Exclude patterns
    final excludePatterns = [
      '.dart_tool',
      'build/',
      '.gradle/',
      '.idea/',
      '.vscode/',
      '.g.dart',        // Generated files
      '.freezed.dart',  // Freezed generated files
      '.gr.dart',       // Auto route generated files
      '.config.dart',   // Config generated files
      '.mocks.dart',    // Mock generated files
    ];
    
    for (final pattern in excludePatterns) {
      if (filePath.contains(pattern)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Scan a single file for color-related content
  /// Returns true if the file likely contains color definitions or usage
  Future<bool> hasColorReferences(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    // Quick heuristic check
    return content.contains('Color(') || 
           content.contains('Color.from') ||
           content.contains('Colors.');
  }
  
  /// Get file statistics
  Future<FileScanStats> getFileStats(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    final lines = await file.readAsLines();
    
    return FileScanStats(
      path: filePath,
      sizeBytes: stat.size,
      lineCount: lines.length,
      lastModified: stat.modified,
    );
  }
}

/// Statistics for a scanned file
class FileScanStats {
  final String path;
  final int sizeBytes;
  final int lineCount;
  final DateTime lastModified;
  
  FileScanStats({
    required this.path,
    required this.sizeBytes,
    required this.lineCount,
    required this.lastModified,
  });
  
  @override
  String toString() => '$path ($lineCount lines, ${_formatBytes(sizeBytes)})';
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
