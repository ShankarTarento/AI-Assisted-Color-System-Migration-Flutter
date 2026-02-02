/// Represents a usage of a color constant in the codebase
class ColorUsage {
  /// The color constant being used (e.g., "AppColors.primaryBlue")
  final String colorReference;
  
  /// File path where the color is used
  final String filePath;
  
  /// Line number where the color is used
  final int lineNumber;
  
  /// Column number where the color is used
  final int columnNumber;
  
  /// The surrounding code context
  final String context;
  
  /// The widget or class where this color is used
  final String? parentWidget;
  
  /// Whether this is a UI context (widget) or non-UI context
  final bool isUiContext;

  ColorUsage({
    required this.colorReference,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.context,
    this.parentWidget,
    this.isUiContext = true,
  });
  
  @override
  String toString() =>
      '$colorReference at $filePath:$lineNumber:$columnNumber';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorUsage &&
          runtimeType == other.runtimeType &&
          colorReference == other.colorReference &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber &&
          columnNumber == other.columnNumber;
  
  @override
  int get hashCode =>
      colorReference.hashCode ^
      filePath.hashCode ^
      lineNumber.hashCode ^
      columnNumber.hashCode;
}
