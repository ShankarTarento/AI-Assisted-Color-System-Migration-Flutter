import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import '../models/color_definition.dart';
import 'color_parser.dart' show Color, ColorParser;

/// AST visitor for finding color definitions in Dart files
class ColorDefinitionVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo? lineInfo;
  final ColorParser parser = ColorParser();
  final List<ColorDefinition> definitions = [];
  
  ColorDefinitionVisitor(this.filePath, this.lineInfo);
  
  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // Check if this is a color field
    final typeAnnotation = node.fields.type;
    if (typeAnnotation?.toString() == 'Color') {
      for (final variable in node.fields.variables) {
        final name = variable.name.toString();
        final initializer = variable.initializer;
        
        if (initializer != null) {
          final code = initializer.toString();
          final color = parser.parseColorLiteral(code);
          
          if (color != null) {
            // Determine qualified name (e.g., AppColors.primaryBlue)
            final className = _getEnclosingClassName(node);
            final qualifiedName = className != null ? '$className.$name' : name;
            
            definitions.add(ColorDefinition(
              name: name,
              qualifiedName: qualifiedName,
              value: color,
              originalCode: code,
              filePath: filePath,
              lineNumber: _getLineNumber(node),
              isConst: node.fields.isConst,
              isStatic: node.staticKeyword != null,
            ));
          }
        }
      }
    }
    
    super.visitFieldDeclaration(node);
  }
  
  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // Handle top-level color constants
    final typeAnnotation = node.variables.type;
    if (typeAnnotation?.toString() == 'Color') {
      for (final variable in node.variables.variables) {
        final name = variable.name.toString();
        final initializer = variable.initializer;
        
        if (initializer != null) {
          final code = initializer.toString();
          final color = parser.parseColorLiteral(code);
          
          if (color != null) {
            definitions.add(ColorDefinition(
              name: name,
              qualifiedName: name,
              value: color,
              originalCode: code,
              filePath: filePath,
              lineNumber: _getLineNumber(node),
              isConst: node.variables.isConst,
              isStatic: false,
            ));
          }
        }
      }
    }
    
    super.visitTopLevelVariableDeclaration(node);
  }
  
  String? _getEnclosingClassName(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        return current.name.toString();
      }
      current = current.parent;
    }
    return null;
  }
  
  int _getLineNumber(AstNode node) {
    if (lineInfo != null) {
      return lineInfo!.getLocation(node.offset).lineNumber;
    }
    return 0;
  }
}

/// AST visitor for finding color usages in Dart files
class ColorUsageVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo? lineInfo;
  final List<ColorUsageInfo> usages = [];
  
  ColorUsageVisitor(this.filePath, this.lineInfo);
  
  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Check for patterns like AppColors.primaryBlue or Colors.blue
    final target = node.target;
    final propertyName = node.propertyName.toString();
    
    if (target != null) {
      final targetName = target.toString();
      
      // Check if this is accessing a color constant
      if (targetName == 'AppColors' || 
          targetName == 'Colors' ||
          targetName.contains('Colors')) {
        final colorReference = '$targetName.$propertyName';
        final lineNumber = _getLineNumber(node);
        final context = _getContext(node);
        
        usages.add(ColorUsageInfo(
          colorReference: colorReference,
          filePath: filePath,
          lineNumber: lineNumber,
          columnNumber: _getColumnNumber(node),
          context: context,
          isUiContext: _isUiContext(node),
        ));
      }
    }
    
    super.visitPropertyAccess(node);
  }
  
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Handle cases like AppColors.primaryBlue used directly
    final prefix = node.prefix.toString();
    final identifier = node.identifier.toString();
    
    if (prefix == 'AppColors' || prefix == 'Colors') {
      final colorReference = '$prefix.$identifier';
      final lineNumber = _getLineNumber(node);
      final context = _getContext(node);
      
      usages.add(ColorUsageInfo(
        colorReference: colorReference,
        filePath: filePath,
        lineNumber: lineNumber,
        columnNumber: _getColumnNumber(node),
        context: context,
        isUiContext: _isUiContext(node),
      ));
    }
    
    super.visitPrefixedIdentifier(node);
  }
  
  int _getLineNumber(AstNode node) {
    if (lineInfo != null) {
      return lineInfo!.getLocation(node.offset).lineNumber;
    }
    return 0;
  }
  
  int _getColumnNumber(AstNode node) {
    if (lineInfo != null) {
      return lineInfo!.getLocation(node.offset).columnNumber;
    }
    return 0;
  }
  
  String _getContext(AstNode node) {
    // Get surrounding code context (parent expression)
    AstNode? current = node.parent;
    while (current != null && current.toString().length < 100) {
      if (current is NamedExpression ||
          current is AssignmentExpression ||
          current is ArgumentList) {
        return current.toString();
      }
      current = current.parent;
    }
    return node.toString();
  }
  
  bool _isUiContext(AstNode node) {
    // Check if this color is used in a UI context (Widget)
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) {
        // Check if return type is Widget
        final returnType = current.returnType?.toString();
        return returnType == 'Widget' || 
               returnType?.endsWith('Widget') == true;
      }
      if (current is InstanceCreationExpression) {
        // Check if creating a Widget
        final type = current.constructorName.type.toString();
        return type.endsWith('Widget') || 
               _isKnownWidget(type);
      }
      current = current.parent;
    }
    return true; // Default to UI context
  }
  
  bool _isKnownWidget(String type) {
    const widgetTypes = [
      'Container', 'Column', 'Row', 'Text', 'Scaffold',
      'AppBar', 'Card', 'Button', 'Icon', 'Material',
      'Box', 'Stack', 'Positioned', 'Padding', 'Center',
    ];
    return widgetTypes.any((w) => type.contains(w));
  }
}

/// Simplified color usage information
class ColorUsageInfo {
  final String colorReference;
  final String filePath;
  final int lineNumber;
  final int columnNumber;
  final String context;
  final bool isUiContext;
  
  ColorUsageInfo({
    required this.colorReference,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.context,
    required this.isUiContext,
  });
}

/// Parse a Dart file and extract color information
class DartFileAnalyzer {
  final ColorParser parser = ColorParser();
  
  /// Analyze a Dart file for color definitions
  Future<List<ColorDefinition>> extractColorDefinitions(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    try {
      final parseResult = parseString(content: content);
      
      final visitor = ColorDefinitionVisitor(filePath, parseResult.lineInfo);
      parseResult.unit.visitChildren(visitor);
      
      return visitor.definitions;
    } catch (e) {
      print('⚠️  Error parsing $filePath: $e');
      return [];
    }
  }
  
  /// Analyze a Dart file for color usages
  Future<List<ColorUsageInfo>> extractColorUsages(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    try {
      final parseResult = parseString(content: content);
      
      final visitor = ColorUsageVisitor(filePath, parseResult.lineInfo);
      parseResult.unit.visitChildren(visitor);
      
      return visitor.usages;
    } catch (e) {
      print('⚠️  Error parsing $filePath: $e');
      return [];
    }
  }
}
