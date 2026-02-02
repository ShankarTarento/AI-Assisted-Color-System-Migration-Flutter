import 'package:analyzer/dart/ast/ast.dart';

/// Analyzes AST nodes to determine BuildContext availability
class ContextAvailabilityAnalyzer {
  /// Check if BuildContext is available at the given node location
  ContextAvailability analyzeNode(AstNode node) {
    // Walk up the AST to find the containing method/function
    AstNode? current = node;
    
    while (current != null) {
      if (current is MethodDeclaration) {
        return _analyzeMethod(current);
      } else if (current is FunctionDeclaration) {
        return _analyzeFunction(current);
      } else if (current is ConstructorDeclaration) {
        return _analyzeConstructor(current);
      }
      
      current = current.parent;
    }
    
    // Top-level or unknown context
    return ContextAvailability.unavailable;
  }
  
  ContextAvailability _analyzeMethod(MethodDeclaration method) {
    // Check if it's a static method
    if (method.isStatic) {
      return ContextAvailability.requiresManual;
    }
    
    // Check if it's a build method
    if (method.name.lexeme == 'build') {
      // build methods have BuildContext parameter
      return ContextAvailability.available;
    }
    
    // Check if BuildContext parameter already exists
    if (hasContextParameter(method)) {
      return ContextAvailability.available;
    }
    
    // Check if this is an instance method in a Widget
    if (_isInWidgetClass(method)) {
      // Can potentially add BuildContext parameter
      return ContextAvailability.canInject;
    }
    
    return ContextAvailability.requiresManual;
  }
  
  ContextAvailability _analyzeFunction(FunctionDeclaration function) {
    // Check if BuildContext parameter exists
    if (hasContextParameter(function)) {
      return ContextAvailability.available;
    }
    
    // Top-level functions can have context injected if they're not const
    final functionExpression = function.functionExpression;
    if (functionExpression.body is! EmptyFunctionBody) {
      return ContextAvailability.canInject;
    }
    
    return ContextAvailability.requiresManual;
  }
  
  ContextAvailability _analyzeConstructor(ConstructorDeclaration constructor) {
    // Const constructors cannot use Theme.of(context)
    if (constructor.constKeyword != null) {
      return ContextAvailability.unavailable;
    }
    
    // Check if BuildContext parameter exists
    if (_hasContextParameterInConstructor(constructor)) {
      return ContextAvailability.available;
    }
    
    return ContextAvailability.requiresManual;
  }
  
  /// Check if a method or function has a BuildContext parameter
  bool hasContextParameter(Declaration declaration) {
    FormalParameterList? parameters;
    
    if (declaration is MethodDeclaration) {
      parameters = declaration.parameters;
    } else if (declaration is FunctionDeclaration) {
      parameters = declaration.functionExpression.parameters;
    }
    
    if (parameters == null) return false;
    
    for (final param in parameters.parameters) {
      if (param is SimpleFormalParameter) {
        final type = param.type;
        if (type != null && type.toString() == 'BuildContext') {
          return true;
        }
      }
    }
    
    return false;
  }
  
  bool _hasContextParameterInConstructor(ConstructorDeclaration constructor) {
    final parameters = constructor.parameters;
    
    for (final param in parameters.parameters) {
      if (param is SimpleFormalParameter) {
        final type = param.type;
        if (type != null && type.toString() == 'BuildContext') {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Check if node is inside a build method
  bool isInBuildMethod(AstNode node) {
    AstNode? current = node;
    
    while (current != null) {
      if (current is MethodDeclaration && current.name.lexeme == 'build') {
        return true;
      }
      current = current.parent;
    }
    
    return false;
  }
  
  /// Check if we can automatically inject BuildContext
  bool canAutoInjectContext(AstNode node) {
    final availability = analyzeNode(node);
    return availability == ContextAvailability.canInject ||
           availability == ContextAvailability.available;
  }
  
  /// Get reasons why manual intervention is needed
  List<String> getManualInterventionReasons(AstNode node) {
    final reasons = <String>[];
    final availability = analyzeNode(node);
    
    if (availability == ContextAvailability.unavailable) {
      AstNode? current = node;
      
      while (current != null) {
        if (current is ConstructorDeclaration && current.constKeyword != null) {
          reasons.add('Cannot use Theme.of(context) in const constructor');
          break;
        }
        current = current.parent;
      }
      
      if (reasons.isEmpty) {
        reasons.add('BuildContext not available in this scope');
      }
    } else if (availability == ContextAvailability.requiresManual) {
      AstNode? current = node;
      
      while (current != null) {
        if (current is MethodDeclaration && current.isStatic) {
          reasons.add('Cannot use Theme.of(context) in static method');
          break;
        }
        current = current.parent;
      }
      
      if (reasons.isEmpty) {
        reasons.add('BuildContext parameter needs to be added manually');
      }
    }
    
    return reasons;
  }
  
  bool _isInWidgetClass(MethodDeclaration method) {
    // Walk up to find the class declaration
    AstNode? current = method.parent;
    
    while (current != null) {
      if (current is ClassDeclaration) {
        // Check if class extends Widget, StatelessWidget, or StatefulWidget
        final extendsClause = current.extendsClause;
        if (extendsClause != null) {
          final superclass = extendsClause.superclass.name2.lexeme;
          if (superclass.contains('Widget')) {
            return true;
          }
        }
        break;
      }
      current = current.parent;
    }
    
    return false;
  }
}

/// Context availability status
enum ContextAvailability {
  /// BuildContext is available in scope (parameter exists)
  available,
  
  /// BuildContext can be added as a parameter automatically
  canInject,
  
  /// Manual intervention required (static method, etc.)
  requiresManual,
  
  /// Cannot use Theme.of(context) here (const constructor, top-level)
  unavailable,
}

/// Context analysis result with details
class ContextAnalysisResult {
  final ContextAvailability availability;
  final List<String> warnings;
  final String? suggestion;
  
  ContextAnalysisResult({
    required this.availability,
    this.warnings = const [],
    this.suggestion,
  });
  
  bool get canUseTheme =>
      availability == ContextAvailability.available ||
      availability == ContextAvailability.canInject;
}
