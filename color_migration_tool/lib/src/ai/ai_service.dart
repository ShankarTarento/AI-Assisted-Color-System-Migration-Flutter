import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dotenv/dotenv.dart';
import '../models/color_definition.dart';
import '../models/mapping_config.dart';

/// AI service for intelligent color migration suggestions
class AIService {
  late final GenerativeModel _model;
  final bool _isEnabled;
  static final DotEnv _env = DotEnv();
  
  AIService() : _isEnabled = _loadConfig() {
    if (_isEnabled) {
      final apiKey = _env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }
      
      _model = GenerativeModel(
        model: _env['AI_MODEL'] ?? 'gemini-pro',
        apiKey: apiKey,
      );
    }
  }
  
  static bool _loadConfig() {
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        _env.load([envFile.path]);
        return _env['ENABLE_AI_SUGGESTIONS']?.toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      print('⚠️  Could not load .env file: $e');
      return false;
    }
  }
  
  bool get isEnabled => _isEnabled;
  
  /// Suggest ColorScheme property for a color based on name and usage
  Future<ColorSchemeSuggestion> suggestColorSchemeMapping(
    ColorDefinition color,
    int usageCount,
  ) async {
    if (!_isEnabled) {
      return ColorSchemeSuggestion(
        property: 'primary',
        confidence: 0.0,
        reasoning: 'AI disabled',
      );
    }
    
    final prompt = '''
You are a Flutter theming expert. Suggest the best Material 3 ColorScheme property for this color.

Color Details:
- Name: ${color.name}
- Qualified Name: ${color.qualifiedName}
- Hex Value: ${color.rgbHex}
- Usage Count: $usageCount usages in codebase

Available ColorScheme properties:
- primary, onPrimary, primaryContainer, onPrimaryContainer
- secondary, onSecondary, secondaryContainer, onSecondaryContainer
- tertiary, onTertiary, tertiaryContainer, onTertiaryContainer
- error, onError, errorContainer, onErrorContainer
- background, onBackground
- surface, onSurface, surfaceVariant, onSurfaceVariant
- outline, outlineVariant
- shadow, scrim
- inverseSurface, onInverseSurface, inversePrimary

Respond in JSON format:
{
  "property": "colorScheme.primary",
  "confidence": 0.85,
  "reasoning": "Color name contains 'primary' and has high usage count"
}
''';
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      // Parse JSON response
      final json = _parseJsonFromText(text);
      
      return ColorSchemeSuggestion(
        property: json['property'] ?? 'primary',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        reasoning: json['reasoning'] ?? 'AI suggestion',
      );
    } catch (e) {
      print('⚠️  AI suggestion failed: $e');
      return ColorSchemeSuggestion(
        property: 'primary',
        confidence: 0.0,
        reasoning: 'Error: $e',
      );
    }
  }
  
  /// Suggest semantic name for a color based on its value
  Future<String> suggestSemanticName(ColorDefinition color) async {
    if (!_isEnabled) return color.name;
    
    final prompt = '''
Suggest a semantic, descriptive name for this color value.

Current Name: ${color.name}
Hex Value: ${color.rgbHex}
RGB: (${color.value.red}, ${color.value.green}, ${color.value.blue})

Requirements:
- Use Material Design naming conventions
- Be descriptive of the color's appearance or purpose
- Use camelCase
- Examples: primaryBlue, errorRed, successGreen, surfaceLight

Respond with just the suggested name, nothing else.
''';
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? color.name;
    } catch (e) {
      print('⚠️  AI naming failed: $e');
      return color.name;
    }
  }
  
  /// Validate a mapping configuration for consistency
  Future<ValidationFeedback> validateMapping(
    MappingConfig config,
    List<ColorDefinition> colors,
  ) async {
    if (!_isEnabled) {
      return ValidationFeedback(
        isValid: true,
        suggestions: [],
        warnings: [],
      );
    }
    
    final prompt = '''
You are a Flutter theming expert. Review this color mapping configuration.

Mapping Summary:
- Strict Mappings (ColorScheme): ${config.strictMappings.length} colors
- Extensions: ${config.extensions.length} groups
- Preserved Colors: ${config.preserved.length} colors

Strict Mappings:
${config.strictMappings.entries.map((e) => '- ${e.key} → ${e.value.target}').join('\n')}

Check for:
1. Duplicate ColorScheme property targets
2. Missing essential ColorScheme properties (primary, error, surface)
3. Colors that should be in ColorScheme but are in extensions
4. Semantic consistency (e.g., "error" colors should map to error scheme)

Respond in JSON format:
{
  "isValid": true,
  "suggestions": ["Consider mapping errorRed to colorScheme.error"],
  "warnings": ["primary property is not mapped"]
}
''';
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final json = _parseJsonFromText(text);
      
      return ValidationFeedback(
        isValid: json['isValid'] ?? true,
        suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
        warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      print('⚠️  AI validation failed: $e');
      return ValidationFeedback(
        isValid: true,
        suggestions: [],
        warnings: ['AI validation unavailable: $e'],
      );
    }
  }
  
  /// Detect potential UI regressions in refactored code
  Future<List<String>> detectPotentialRegressions(
    String originalCode,
    String refactoredCode,
  ) async {
    if (!_isEnabled) return [];
    
    final prompt = '''
You are a Flutter code reviewer. Compare these code snippets for potential issues.

Original Code:
```dart
$originalCode
```

Refactored Code:
```dart
$refactoredCode
```

Identify potential issues:
1. BuildContext not available
2. Const constructors broken
3. Static method usage
4. Null safety violations

Return a JSON array of issue descriptions:
["BuildContext may not be available in static method", "Const constructor cannot use Theme.of(context)"]
''';
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final list = _parseJsonArrayFromText(text);
      return list.cast<String>();
    } catch (e) {
      print('⚠️  AI regression detection failed: $e');
      return [];
    }
  }
  
  Map<String, dynamic> _parseJsonFromText(String text) {
    try {
      // Extract JSON from markdown code blocks if present
      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(text);
      final jsonText = (jsonMatch?.group(1) ?? text).trim();
      
      // Parse with dart:convert
      final decoded = jsonDecode(jsonText);
      
      // Ensure it's a Map
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        // Convert to Map<String, dynamic> if needed
        return Map<String, dynamic>.from(decoded);
      }
      
      print('⚠️  AI response is not a JSON object');
      return {};
    } catch (e) {
      print('⚠️  JSON parsing failed: $e');
      print('   Raw text: ${text.substring(0, text.length > 200 ? 200 : text.length)}...');
      return {};
    }
  }
  
  List<dynamic> _parseJsonArrayFromText(String text) {
    try {
      // Extract from markdown code blocks if present
      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(text);
      final jsonText = (jsonMatch?.group(1) ?? text).trim();
      
      // Parse with dart:convert
      final decoded = jsonDecode(jsonText);
      
      // Ensure it's a List
      if (decoded is List) {
        return decoded;
      }
      
      print('⚠️  AI response is not a JSON array');
      return [];
    } catch (e) {
      print('⚠️  JSON array parsing failed: $e');
      return [];
    }
  }
}

/// AI suggestion for ColorScheme property
class ColorSchemeSuggestion {
  final String property;
  final double confidence;
  final String reasoning;
  
  ColorSchemeSuggestion({
    required this.property,
    required this.confidence,
    required this.reasoning,
  });
}

/// AI validation feedback
class ValidationFeedback {
  final bool isValid;
  final List<String> suggestions;
  final List<String> warnings;
  
  ValidationFeedback({
    required this.isValid,
    required this.suggestions,
    required this.warnings,
  });
  
  void printReport() {
    if (suggestions.isNotEmpty) {
      print('\n💡 AI Suggestions:');
      for (final suggestion in suggestions) {
        print('  • $suggestion');
      }
    }
    
    if (warnings.isNotEmpty) {
      print('\n🤖 AI Warnings:');
      for (final warning in warnings) {
        print('  • $warning');
      }
    }
  }
}
