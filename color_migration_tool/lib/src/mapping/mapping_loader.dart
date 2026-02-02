import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/mapping_config.dart';

/// Loads and parses mapping configuration files
class MappingLoader {
  /// Load mapping configuration from YAML file
  Future<MappingConfig> loadFromFile(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('Mapping file not found: $filePath');
    }
    
    final content = await file.readAsString();
    return loadFromYaml(content);
  }
  
  /// Load mapping configuration from YAML string
  MappingConfig loadFromYaml(String yamlContent) {
    final dynamic yaml = loadYaml(yamlContent);
    
    if (yaml is! Map) {
      throw Exception('Invalid mapping configuration: root must be a map');
    }
    
    return MappingConfig.fromJson(yaml.cast<String, dynamic>());
  }
  
  /// Save mapping configuration to YAML file
  Future<void> saveToFile(MappingConfig config, String filePath) async {
    final yaml = _configToYaml(config);
    
    final file = File(filePath);
    await file.writeAsString(yaml);
    
    print('✅ Mapping configuration saved to: $filePath');
  }
  
  /// Convert mapping config to YAML string
  String _configToYaml(MappingConfig config) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('# Color Mapping Configuration');
    buffer.writeln('# Generated: ${DateTime.now()}');
    buffer.writeln('# Version: ${config.version}');
    buffer.writeln();
    
    buffer.writeln('version: "${config.version}"');
    buffer.writeln();
    
    // Strict mappings
    if (config.strictMappings.isNotEmpty) {
      buffer.writeln('# Core colors mapped to ColorScheme');
      buffer.writeln('strict_mappings:');
      
      for (final entry in config.strictMappings.entries) {
        buffer.writeln('  ${entry.key}:');
        buffer.writeln('    target: ${entry.value.target}');
        if (entry.value.verifyValue != null) {
          buffer.writeln('    verify_value: "${entry.value.verifyValue}"');
        }
        if (entry.value.description != null) {
          buffer.writeln('    description: "${entry.value.description}"');
        }
      }
      buffer.writeln();
    }
    
    // Extensions
    if (config.extensions.isNotEmpty) {
      buffer.writeln('# Non-core colors grouped into ThemeExtensions');
      buffer.writeln('extensions:');
      
      for (final extEntry in config.extensions.entries) {
        buffer.writeln('  ${extEntry.key}:');
        
        for (final colorEntry in extEntry.value.colors.entries) {
          buffer.writeln('    ${colorEntry.key}:');
          buffer.writeln('      target: ${colorEntry.value.target}');
          buffer.writeln('      value: "${colorEntry.value.value}"');
        }
        buffer.writeln();
      }
    }
    
    // Preserved colors
    if (config.preserved.isNotEmpty) {
      buffer.writeln('# Colors to preserve unchanged');
      buffer.writeln('preserved:');
      for (final color in config.preserved) {
        buffer.writeln('  - $color');
      }
      buffer.writeln();
    }
    
    // Rules
    buffer.writeln('# Migration rules');
    buffer.writeln('rules:');
    buffer.writeln('  require_value_match: ${config.rules.requireValueMatch}');
    buffer.writeln('  block_if_mismatch: ${config.rules.blockIfMismatch}');
    buffer.writeln('  auto_generate: ${config.rules.autoGenerate}');
    buffer.writeln('  group_similar_colors: ${config.rules.groupSimilarColors}');
    
    return buffer.toString();
  }
}
