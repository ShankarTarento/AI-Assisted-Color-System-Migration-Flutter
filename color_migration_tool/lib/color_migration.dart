/// AI-assisted Flutter color system migration tool
/// 
/// This library provides tools to safely migrate Flutter applications from
/// large color constants classes to semantic theming systems.
library color_migration;

// Core models
export 'src/models/color_definition.dart';
export 'src/models/color_usage.dart';
export 'src/models/classification.dart';
export 'src/models/mapping_config.dart';

// Analyzer
export 'src/analyzer/color_scanner.dart';
export 'src/analyzer/color_parser.dart';
export 'src/analyzer/usage_analyzer.dart';

// Classifier
export 'src/classifier/color_classifier.dart';

// Mapping
export 'src/mapping/mapping_validator.dart';
export 'src/mapping/mapping_loader.dart';

// Generator
export 'src/generator/theme_generator.dart';
export 'src/generator/extension_generator.dart';

// Refactor
export 'src/refactor/code_refactorer.dart';

// Reporting
export 'src/reporting/audit_reporter.dart';

// Version
const String version = '0.1.0';
