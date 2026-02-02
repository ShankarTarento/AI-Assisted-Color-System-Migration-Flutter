import 'package:test/test.dart';
import 'package:color_migration_tool/src/analyzer/color_parser.dart';

void main() {
  group('ColorParser', () {
    late ColorParser parser;
    
    setUp(() {
      parser = ColorParser();
    });
    
    test('should parse Color(0xAARRGGBB) format', () {
      final color = parser.parseColorLiteral('Color(0xFF1976D2)');
      
      expect(color, isNotNull);
      expect(color!.value, equals(0xFF1976D2));
    });
    
    test('should parse Color.fromARGB format', () {
      final color = parser.parseColorLiteral('Color.fromARGB(255, 25, 118, 210)');
      
      expect(color, isNotNull);
      expect(color!.alpha, equals(255));
      expect(color.red, equals(25));
      expect(color.green, equals(118));
      expect(color.blue, equals(210));
    });
    
    test('should parse Color.fromRGBO format', () {
      final color = parser.parseColorLiteral('Color.fromRGBO(25, 118, 210, 1.0)');
      
      expect(color, isNotNull);
      expect(color!.red, equals(25));
      expect(color.green, equals(118));
      expect(color.blue, equals(210));
    });
    
    test('should normalize color to ARGB hex', () {
      final color = Color(0xFF1976D2);
      final normalized = parser.normalizeToARGB(color);
      
      expect(normalized, equals('0xFF1976D2'));
    });
    
    test('should convert color to RGB hex', () {
      final color = Color(0xFF1976D2);
      final hex = parser.toRGBHex(color);
      
      expect(hex, equals('#1976D2'));
    });
    
    test('should extract color name from definition', () {
      final line = 'static const Color primaryBlue = Color(0xFF1976D2);';
      final name = parser.extractColorName(line);
      
      expect(name, equals('primaryBlue'));
    });
    
    test('should detect color definition', () {
      final line = 'static const Color primaryBlue = Color(0xFF1976D2);';
      
      expect(parser.isColorDefinition(line), isTrue);
    });
    
    test('should detect color usage', () {
      final line = 'backgroundColor: AppColors.primaryBlue,';
      
      expect(parser.isColorUsage(line), isTrue);
    });
  });
}
