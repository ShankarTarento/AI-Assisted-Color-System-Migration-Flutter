/// Mapping configuration model for color migration
class MappingConfig {
  final String version;
  final Map<String, StrictMapping> strictMappings;
  final Map<String, ExtensionGroup> extensions;
  final List<String> preserved;
  final MappingRules rules;
  
  MappingConfig({
    required this.version,
    required this.strictMappings,
    required this.extensions,
    required this.preserved,
    required this.rules,
  });
  
  factory MappingConfig.fromJson(Map<String, dynamic> json) {
    // Handle rules which might be null or a YamlMap
    Map<String, dynamic> rulesMap = {};
    if (json['rules'] != null) {
      final rulesData = json['rules'];
      if (rulesData is Map) {
        rulesMap = Map<String, dynamic>.from(rulesData);
      }
    }
    
    return MappingConfig(
      version: json['version'] as String? ?? '1.0',
      strictMappings: _parseStrictMappings(json['strict_mappings']),
      extensions: _parseExtensions(json['extensions']),
      preserved: (json['preserved'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      rules: MappingRules.fromJson(rulesMap),
    );
  }
  
  static Map<String, StrictMapping> _parseStrictMappings(dynamic data) {
    if (data == null) return {};
    
    final map = data is Map ? Map<String, dynamic>.from(data) : data as Map<String, dynamic>;
    return map.map((key, value) {
      final valueMap = value is Map ? Map<String, dynamic>.from(value) : value as Map<String, dynamic>;
      return MapEntry(
        key,
        StrictMapping.fromJson(valueMap),
      );
    });
  }
  
  static Map<String, ExtensionGroup> _parseExtensions(dynamic data) {
    if (data == null) return {};
    
    final map = data is Map ? Map<String, dynamic>.from(data) : data as Map<String, dynamic>;
    return map.map((key, value) {
      final valueMap = value is Map ? Map<String, dynamic>.from(value) : value as Map<String, dynamic>;
      return MapEntry(
        key,
        ExtensionGroup.fromJson(valueMap),
      );
    });
  }
}

/// Strict mapping to ColorScheme
class StrictMapping {
  final String target;
  final String? verifyValue;
  final String? description;
  
  StrictMapping({
    required this.target,
    this.verifyValue,
    this.description,
  });
  
  factory StrictMapping.fromJson(Map<String, dynamic> json) {
    return StrictMapping(
      target: json['target'] as String,
      verifyValue: json['verify_value'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Extension group for ThemeExtension
class ExtensionGroup {
  final Map<String, ExtensionColor> colors;
  
  ExtensionGroup({required this.colors});
  
  factory ExtensionGroup.fromJson(Map<String, dynamic> json) {
    final colors = <String, ExtensionColor>{};
    
    for (final entry in json.entries) {
      final valueMap = entry.value is Map 
          ? Map<String, dynamic>.from(entry.value as Map)
          : entry.value as Map<String, dynamic>;
      colors[entry.key] = ExtensionColor.fromJson(valueMap);
    }
    
    return ExtensionGroup(colors: colors);
  }
}

/// Extension color mapping
class ExtensionColor {
  final String target;
  final String value;
  
  ExtensionColor({
    required this.target,
    required this.value,
  });
  
  factory ExtensionColor.fromJson(Map<String, dynamic> json) {
    return ExtensionColor(
      target: json['target'] as String,
      value: json['value'] as String,
    );
  }
}

/// Mapping rules
class MappingRules {
  final bool requireValueMatch;
  final bool blockIfMismatch;
  final bool autoGenerate;
  final bool groupSimilarColors;
  
  MappingRules({
    this.requireValueMatch = true,
    this.blockIfMismatch = true,
    this.autoGenerate = true,
    this.groupSimilarColors = true,
  });
  
  factory MappingRules.fromJson(Map<String, dynamic> json) {
    return MappingRules(
      requireValueMatch: json['require_value_match'] as bool? ?? true,
      blockIfMismatch: json['block_if_mismatch'] as bool? ?? true,
      autoGenerate: json['auto_generate'] as bool? ?? true,
      groupSimilarColors: json['group_similar_colors'] as bool? ?? true,
    );
  }
}
