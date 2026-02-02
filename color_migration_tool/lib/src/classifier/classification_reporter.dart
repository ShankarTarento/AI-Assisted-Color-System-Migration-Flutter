import 'dart:convert';
import 'dart:io';
import '../models/classification.dart';
import '../analyzer/usage_analyzer.dart';
import '../classifier/color_classifier.dart';

/// Generates classification reports
class ClassificationReporter {
  /// Generate JSON classification report
  Future<void> generateJsonReport(
    Map<String, ColorClassification> classifications,
    String outputPath,
  ) async {
    // Group by category
    final byCategory = <String, List<Map<String, dynamic>>>{};
    
    for (final classification in classifications.values) {
      final categoryName = classification.category.toString().split('.').last;
      byCategory.putIfAbsent(categoryName, () => []);
      
      byCategory[categoryName]!.add({
        'name': classification.color.name,
        'qualified_name': classification.color.qualifiedName,
        'value': classification.color.rgbHex,
        'usage_count': classification.usageCount,
        'file_count': classification.fileCount,
        'confidence': classification.confidence,
        'reason': classification.reason,
        'parent_color': classification.parentColor?.qualifiedName,
        'similarity': classification.similarityToParent,
      });
    }
    
    final report = {
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_colors': classifications.length,
      },
      'summary': _generateSummary(classifications),
      'classifications': byCategory,
    };
    
    final file = File(outputPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    
    print('✅ Classification report saved to: $outputPath');
  }
  
  /// Generate classification summary
  Map<String, dynamic> _generateSummary(
    Map<String, ColorClassification> classifications,
  ) {
    final summary = <ColorCategory, int>{};
    
    for (final classification in classifications.values) {
      summary[classification.category] = 
          (summary[classification.category] ?? 0) + 1;
    }
    
    return {
      'core_colors': summary[ColorCategory.core] ?? 0,
      'variant_colors': summary[ColorCategory.variant] ?? 0,
      'component_colors': summary[ColorCategory.component] ?? 0,
      'legacy_colors': summary[ColorCategory.legacy] ?? 0,
      'unused_colors': summary[ColorCategory.unused] ?? 0,
    };
  }
  
  /// Print classification summary to console
  void printSummary(Map<String, ColorClassification> classifications) {
    final summary = _generateSummary(classifications);
    
    print('\n📊 Classification Summary');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Total Colors:       ${classifications.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Core Colors:      ${summary['core_colors']}');
    print('🎨 Variant Colors:   ${summary['variant_colors']}');
    print('🧩 Component Colors: ${summary['component_colors']}');
    print('📦 Legacy Colors:    ${summary['legacy_colors']}');
    print('❌ Unused Colors:    ${summary['unused_colors']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // Show core colors
    final coreColors = classifications.values
        .where((c) => c.category == ColorCategory.core)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    if (coreColors.isNotEmpty) {
      print('🔝 Core Colors (High Usage):');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      for (final classification in coreColors.take(10)) {
        print('  ${classification.color.qualifiedName.padRight(35)} '
              '${classification.color.rgbHex.padRight(10)} '
              '→ ${classification.usageCount} usages');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
    
    // Show variants
    final variants = classifications.values
        .where((c) => c.category == ColorCategory.variant)
        .toList();
    
    if (variants.isNotEmpty) {
      print('🎨 Color Variants (${variants.length} total):');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      for (final classification in variants.take(10)) {
        print('  ${classification.color.qualifiedName.padRight(35)} '
              '→ variant of ${classification.parentColor?.name ?? "unknown"}');
      }
      if (variants.length > 10) {
        print('  ... and ${variants.length - 10} more');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
  }
  
  /// Run classification and generate report
  Future<Map<String, ColorClassification>> classifyAndReport(
    ProjectColorAnalysis analysis, {
    String? outputPath,
  }) async {
    final classifier = ColorClassifier();
    final classifications = classifier.classifyColors(analysis);
    
    printSummary(classifications);
    
    if (outputPath != null) {
      await generateJsonReport(classifications, outputPath);
    }
    
    return classifications;
  }
}
