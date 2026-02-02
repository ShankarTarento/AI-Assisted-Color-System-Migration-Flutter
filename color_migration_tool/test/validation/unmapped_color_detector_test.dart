import 'package:test/test.dart';
import 'package:color_migration_tool/src/validation/unmapped_color_detector.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('UnmappedColorDetector', () {
    late UnmappedColorDetector detector;
    
    setUp(() {
      detector = UnmappedColorDetector();
    });
    
    test('should find unmapped colors', () {
      // Create test data with unmapped colors
      final analysis = createTestAnalysis(colorCount: 10);
      final mapping = createTestMapping(
        strictMappingCount: 5,  // Only 5 colors mapped
        preservedCount: 0,
      );
      
      final unmapped = detector.findUnmappedColors(
        analysis: analysis,
        config: mapping,
      );
      
      // Should find 5 unmapped colors (10 total - 5 mapped)
      expect(unmapped.length, greaterThan(0));
    });
    
    test('should not find unmapped colors when all are mapped', () {
      final analysis = createTestAnalysis(colorCount: 5);
      final mapping = createTestMapping(
        strictMappingCount: 5,  // All colors mapped
      );
      
      final unmapped = detector.findUnmappedColors(
        analysis: analysis,
        config: mapping,
      );
      
      expect(unmapped, isEmpty);
    });
    
    test('should categorize by severity based on usage count', () {
      final analysis = createTestAnalysis(
        colorCount: 3,
        usageCount: 30, // 10 usages per color
      );
      final mapping = createTestMapping(strictMappingCount: 0); // None mapped
      
      final unmapped = detector.findUnmappedColors(
        analysis: analysis,
        config: mapping,
      );
      
      // All should be critical (>=10 usages)
      expect(unmapped.every((u) => u.severity == UnmappedSeverity.critical), isTrue);
    });
    
    test('should generate correct report', () {
      final analysis = createTestAnalysis(colorCount: 10);
      final mapping = createTestMapping(strictMappingCount: 5);
      
      final unmapped = detector.findUnmappedColors(
        analysis: analysis,
        config: mapping,
      );
      final report = detector.generateReport(unmapped);
      
      expect(report.totalUnmapped, equals(unmapped.length));
      expect(report.hasUnmappedColors, isTrue);
    });
    
    test('should sort unmapped colors by usage count', () {
      final analysis = createTestAnalysis(colorCount: 5);
      final mapping = createTestMapping(strictMappingCount: 0);
      
      final unmapped = detector.findUnmappedColors(
        analysis: analysis,
        config: mapping,
      );
      
      // Check sorting (descending by usage count)
      for (var i = 0; i < unmapped.length - 1; i++) {
        expect(
          unmapped[i].usageCount,
          greaterThanOrEqualTo(unmapped[i + 1].usageCount),
        );
      }
    });
  });
}
