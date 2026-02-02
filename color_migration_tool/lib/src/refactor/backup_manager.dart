import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Manages file backups for safe refactoring with rollback capability
class BackupManager {
  final String projectPath;
  final String backupBasePath;
  
  BackupManager({
    required this.projectPath,
    String? backupBasePath,
  }) : backupBasePath = backupBasePath ?? '$projectPath/.color_migrate_backups';
  
  /// Create a backup of files before refactoring
  Future<BackupInfo> createBackup(List<String> filePaths) async {
    final timestamp = DateTime.now();
    final backupId = timestamp.millisecondsSinceEpoch.toString();
    final backupDir = Directory('$backupBasePath/$backupId');
    
    print('📦 Creating backup: $backupId');
    
    // Create backup directory
    await backupDir.create(recursive: true);
    
    final fileHashes = <String, String>{};
    var filesBackedUp = 0;
    
    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
        if (!await file.exists()) continue;
        
        // Calculate relative path
        final relativePath = filePath.replaceFirst('$projectPath/', '');
        
        // Create subdirectories if needed
        final backupFile = File('${backupDir.path}/$relativePath');
        await backupFile.parent.create(recursive: true);
        
        // Copy file
        await file.copy(backupFile.path);
        
        // Calculate hash for verification
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();
        fileHashes[relativePath] = hash;
        
        filesBackedUp++;
      } catch (e) {
        print('  ⚠️  Failed to backup $filePath: $e');
      }
    }
    
    // Save backup metadata
    final backupInfo = BackupInfo(
      id: backupId,
      timestamp: timestamp,
      fileCount: filesBackedUp,
      location: backupDir.path,
      fileHashes: fileHashes,
    );
    
    final metadataFile = File('${backupDir.path}/.backup_metadata.json');
    await metadataFile.writeAsString(jsonEncode(backupInfo.toJson()));
    
    print('✓ Backed up $filesBackedUp files');
    
    return backupInfo;
  }
  
  /// Restore files from a backup
  Future<void> restoreBackup(String backupId) async {
    final backupDir = Directory('$backupBasePath/$backupId');
    
    if (!await backupDir.exists()) {
      throw Exception('Backup not found: $backupId');
    }
    
    print('♻️   Restoring backup: $backupId');
    
    // Load metadata
    final metadataFile = File('${backupDir.path}/.backup_metadata.json');
    if (!await metadataFile.exists()) {
      throw Exception('Backup metadata not found');
    }
    
    final metadata = BackupInfo.fromJson(
      jsonDecode(await metadataFile.readAsString()),
    );
    
    var filesRestored = 0;
    var hashMismatches = 0;
    
    for (final entry in metadata.fileHashes.entries) {
      try {
        final relativePath = entry.key;
        final expectedHash = entry.value;
        
        final backupFile = File('${backupDir.path}/$relativePath');
        if (!await backupFile.exists()) {
          print('  ⚠️  Backup file missing: $relativePath');
          continue;
        }
        
        // Verify backup file hash
        final backupBytes = await backupFile.readAsBytes();
        final backupHash = sha256.convert(backupBytes).toString();
        
        if (backupHash != expectedHash) {
          print('  ⚠️  Hash mismatch for $relativePath');
          hashMismatches++;
        }
        
        // Restore file
        final targetFile = File('$projectPath/$relativePath');
        await targetFile.parent.create(recursive: true);
        await backupFile.copy(targetFile.path);
        
        filesRestored++;
      } catch (e) {
        print('  ⚠️  Failed to restore ${entry.key}: $e');
      }
    }
    
    print('✓ Restored $filesRestored files');
    if (hashMismatches > 0) {
      print('⚠️  $hashMismatches files had hash mismatches');
    }
  }
  
  /// List all available backups
  Future<List<BackupInfo>> listBackups() async {
    final backupsDir = Directory(backupBasePath);
    
    if (!await backupsDir.exists()) {
      return [];
    }
    
    final backups = <BackupInfo>[];
    
    await for (final entity in backupsDir.list()) {
      if (entity is Directory) {
        try {
          final metadataFile = File('${entity.path}/.backup_metadata.json');
          if (await metadataFile.exists()) {
            final metadata = BackupInfo.fromJson(
              jsonDecode(await metadataFile.readAsString()),
            );
            backups.add(metadata);
          }
        } catch (e) {
          // Skip invalid backups
        }
      }
    }
    
    // Sort by timestamp (newest first)
    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return backups;
  }
  
  /// Delete a backup
  Future<void> deleteBackup(String backupId) async {
    final backupDir = Directory('$backupBasePath/$backupId');
    
    if (!await backupDir.exists()) {
      throw Exception('Backup not found: $backupId');
    }
    
    await backupDir.delete(recursive: true);
    print('🗑️  Deleted backup: $backupId');
  }
  
  /// Verify backup integrity
  Future<BackupVerificationResult> verifyBackup(String backupId) async {
    final backupDir = Directory('$backupBasePath/$backupId');
    
    if (!await backupDir.exists()) {
      throw Exception('Backup not found: $backupId');
    }
    
    // Load metadata
    final metadataFile = File('${backupDir.path}/.backup_metadata.json');
    if (!await metadataFile.exists()) {
      throw Exception('Backup metadata not found');
    }
    
    final metadata = BackupInfo.fromJson(
      jsonDecode(await metadataFile.readAsString()),
    );
    
    var verified = 0;
    var missing = 0;
    var corrupted = 0;
    
    for (final entry in metadata.fileHashes.entries) {
      final backupFile = File('${backupDir.path}/${entry.key}');
      
      if (!await backupFile.exists()) {
        missing++;
        continue;
      }
      
      final bytes = await backupFile.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      
      if (hash != entry.value) {
        corrupted++;
      } else {
        verified++;
      }
    }
    
    return BackupVerificationResult(
      isValid: missing == 0 && corrupted == 0,
      totalFiles: metadata.fileCount,
      verifiedFiles: verified,
      missingFiles: missing,
      corruptedFiles: corrupted,
    );
  }
}

/// Backup metadata
class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int fileCount;
  final String location;
  final Map<String, String> fileHashes;
  
  BackupInfo({
    required this.id,
    required this.timestamp,
    required this.fileCount,
    required this.location,
    required this.fileHashes,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'fileCount': fileCount,
    'location': location,
    'fileHashes': fileHashes,
  };
  
  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    fileCount: json['fileCount'] as int,
    location: json['location'] as String,
    fileHashes: Map<String, String>.from(json['fileHashes'] as Map),
  );
}

/// Backup verification result
class BackupVerificationResult {
  final bool isValid;
  final int totalFiles;
  final int verifiedFiles;
  final int missingFiles;
  final int corruptedFiles;
  
  BackupVerificationResult({
    required this.isValid,
    required this.totalFiles,
    required this.verifiedFiles,
    required this.missingFiles,
    required this.corruptedFiles,
  });
}
