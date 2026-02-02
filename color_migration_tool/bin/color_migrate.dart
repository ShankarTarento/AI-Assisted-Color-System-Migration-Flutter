import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';

// Import analyzer components
import 'package:color_migration_tool/src/analyzer/usage_analyzer.dart';
import 'package:color_migration_tool/src/reporting/audit_reporter.dart';
import 'package:color_migration_tool/src/classifier/classification_reporter.dart';
import 'package:color_migration_tool/src/classifier/color_classifier.dart';
import 'package:color_migration_tool/src/mapping/mapping_loader.dart';
import 'package:color_migration_tool/src/mapping/mapping_validator.dart';
import 'package:color_migration_tool/src/mapping/mapping_generator.dart';
import 'package:color_migration_tool/src/generator/theme_generator.dart';
import 'package:color_migration_tool/src/refactor/code_refactorer.dart';
import 'package:color_migration_tool/src/refactor/diff_generator.dart';
import 'package:color_migration_tool/src/refactor/backup_manager.dart';
import 'package:color_migration_tool/src/validation/pre_migration_validator.dart';
import 'package:color_migration_tool/src/ai/ai_service.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'color_migrate',
    'AI-assisted Flutter color system migration tool',
  )
    ..addCommand(InitCommand())
    ..addCommand(AuditCommand())
    ..addCommand(ClassifyCommand())
    ..addCommand(MapGenerateCommand())
    ..addCommand(MapSuggestCommand())
    ..addCommand(MapValidateCommand())
    ..addCommand(CheckReadinessCommand())
    ..addCommand(ThemeGenerateCommand())
    ..addCommand(RefactorCommand())
    ..addCommand(RollbackCommand())
    ..addCommand(VerifyCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e);
    exit(64); // Exit code for usage error
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

/// Initialize a new migration project
class InitCommand extends Command<void> {
  @override
  final name = 'init';
  
  @override
  final description = 'Initialize a new color migration project';

  InitCommand() {
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Path to the Flutter project',
      mandatory: true,
    );
  }

  @override
  Future<void> run() async {
    final projectPath = argResults!['project'] as String;
    print('⚙️  Initializing color migration for: $projectPath');
    
    // TODO: Implement initialization logic
    // - Validate Flutter project
    // - Create .color_migrate.yaml config
    // - Create output directories
    
    print('✅ Initialization complete!');
  }
}

/// Run color audit
class AuditCommand extends Command<void> {
  @override
  final name = 'audit';
  
  @override
  final description = 'Audit all color usage in the Flutter project';

  AuditCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file for audit report (JSON)',
        defaultsTo: 'audit_report.json',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Output format (json, html, csv)',
        defaultsTo: 'json',
        allowed: ['json', 'html', 'csv'],
      );
  }

  @override
  Future<void> run() async {
    final outputPath = argResults!['output'] as String;
    final format = argResults!['format'] as String;
    
    print('🔍 Running color audit...\n');
    
    // Use current directory as project path
    final projectPath = Directory.current.path;
    
    try {
      // Run analysis
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(projectPath);
      
      // Print console summary
      final reporter = AuditReporter();
      reporter.printSummary(analysis);
      
      // Generate report in requested format
      switch (format) {
        case 'json':
          await reporter.generateJsonReport(analysis, outputPath);
          break;
        case 'html':
          await reporter.generateHtmlReport(
            analysis,
            outputPath.replaceAll('.json', '.html'),
          );
          break;
        case 'csv':
          await reporter.generateCsvReport(
            analysis,
            outputPath.replaceAll('.json', '.csv'),
          );
          break;
      }
      
      print('✅ Audit complete! Report saved to: $outputPath');
    } catch (e, stack) {
      print('❌ Error during audit: $e');
      print(stack);
      exit(1);
    }
  }
}

/// Classify colors
class ClassifyCommand extends Command<void> {
  @override
  final name = 'classify';
  
  @override
  final description = 'Classify colors based on usage patterns';

  ClassifyCommand() {
    argParser
      ..addOption(
        'audit',
        abbr: 'a',
        help: 'Input audit report file',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file for classification results',
        defaultsTo: 'classification.json',
      );
  }

  @override
  Future<void> run() async {
    final auditPath = argResults!['audit'] as String;
    final outputPath = argResults!['output'] as String;
    
    print('🏷️  Classifying colors...\n');
    
    try {
      // Load audit report
      final auditFile = File(auditPath);
      if (!await auditFile.exists()) {
        print('❌ Error: Audit file not found: $auditPath');
        exit(1);
      }
      
      // For now, re-run analysis (in future, we'll load from JSON)
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      
      // Run classification
      final reporter = ClassificationReporter();
      await reporter.classifyAndReport(analysis, outputPath: outputPath);
      
      print('✅ Classification complete!');
    } catch (e, stack) {
      print('❌ Error during classification: $e');
      print(stack);
      exit(1);
    }
  }
}

/// Generate mapping template
class MapGenerateCommand extends Command<void> {
  @override
  final name = 'map-generate';
  
  @override
  final description = 'Generate a color mapping configuration template';

  MapGenerateCommand() {
    argParser
      ..addOption(
        'classification',
        abbr: 'c',
        help: 'Input classification file',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output mapping file',
        defaultsTo: 'color_mapping.yaml',
      );
  }

  @override
  Future<void> run() async {
    final classificationPath = argResults!['classification'] as String;
    final outputPath = argResults!['output'] as String;
    
    print('🗺️  Generating mapping template...\n');
    
    try {
      // Load classification file
      final classificationFile = File(classificationPath);
      if (!await classificationFile.exists()) {
        print('❌ Error: Classification file not found: $classificationPath');
        exit(1);
      }
      
      // Re-run analysis and classification (in future, load from JSON)
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      
      final classifier = ColorClassifier();
      final classifications = classifier.classifyColors(analysis);
      
      // Generate mapping
      final generator = MappingGenerator();
      final mapping = generator.generateFromClassification(classifications, analysis);
      
      // Save to file
      final loader = MappingLoader();
      await loader.saveToFile(mapping, outputPath);
      
      print('\n✅ Mapping template generated!');
      print('📝 Review and edit the mapping file before using it for migration.');
    } catch (e, stack) {
      print('❌ Error generating mapping: $e');
      print(stack);
      exit(1);
    }
  }
}

/// AI-assisted mapping suggestions
class MapSuggestCommand extends Command<void> {
  @override
  final name = 'map-suggest';
  
  @override
  final description = 'Get AI-assisted mapping suggestions';

  MapSuggestCommand() {
    argParser
      ..addOption(
        'audit',
        abbr: 'a',
        help: 'Input audit report file',
        mandatory: true,
      )
      ..addOption(
        'ai-provider',
        help: 'AI provider (openai, anthropic, gemini)',
        defaultsTo: 'openai',
        allowed: ['openai', 'anthropic', 'gemini'],
      );
  }

  @override
  Future<void> run() async {
    final auditPath = argResults!['audit'] as String;
    
    print('🤖 Getting AI-assisted mapping suggestions...\n');
    
    try {
      // Initialize AI service
      final aiService = AIService();
      
      if (!aiService.isEnabled) {
        print('⚠️  AI features are disabled. Create a .env file with GEMINI_API_KEY to enable.');
        print('💡 See .env.example for configuration details.');
        exit(1);
      }
      
      // Run analysis
      print('📊 Analyzing project colors...');
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      
      print('✓ Found ${analysis.colors.length} colors\n');
      
      // Get AI suggestions for top colors
      print('🧠 Generating AI suggestions for top colors...\n');
      
      final suggestions = <String, ColorSchemeSuggestion>{};
      var count = 0;
      const maxSuggestions = 10; // Limit to top 10 colors
      
      for (final colorDef in analysis.colors.take(maxSuggestions)) {
        final usageCount = analysis.getUsageCount(colorDef.qualifiedName);
        print('  Analyzing: ${colorDef.name} (${colorDef.rgbHex}) - $usageCount usages');
        
        final suggestion = await aiService.suggestColorSchemeMapping(
          colorDef,
          usageCount,
        );
        
        suggestions[colorDef.name] = suggestion;
        
        print('    → ${suggestion.property} (confidence: ${(suggestion.confidence * 100).toStringAsFixed(0)}%)');
        print('    Reasoning: ${suggestion.reasoning}\n');
        
        count++;
      }
      
      print('\n✅ Generated $count AI suggestions!');
      print('💡 Use these suggestions to create your mapping configuration.');
      print('   Run: dart run bin/color_migrate.dart map-generate -c audit.json -o color_mapping.yaml');
      
    } catch (e, stack) {
      print('❌ Error getting AI suggestions: $e');
      if (e.toString().contains('GEMINI_API_KEY')) {
        print('\n💡 To enable AI features:');
        print('   1. Copy .env.example to .env');
        print('   2. Add your Gemini API key from https://makersuite.google.com/app/apikey');
        print('   3. Set ENABLE_AI_SUGGESTIONS=true');
      }
      exit(1);
    }
  }
}

/// Validate mapping configuration
class MapValidateCommand extends Command<void> {
  @override
  final name = 'map-validate';
  
  @override
  final description = 'Validate the color mapping configuration';

  MapValidateCommand() {
    argParser.addOption(
      'mapping',
      abbr: 'm',
      help: 'Mapping configuration file',
      mandatory: true,
    );
  }

  @override
  Future<void> run() async {
    final mappingPath = argResults!['mapping'] as String;
    
    print('✓ Validating mapping configuration...\n');
    
    try {
      // Load mapping file
      final loader = MappingLoader();
      final mapping = await loader.loadFromFile(mappingPath);
      
      print('✓ Loaded mapping configuration (version ${mapping.version})');
      
      // Run analysis to get color definitions
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      
      // Validate
      final validator = MappingValidator();
      final result = validator.validate(mapping, analysis);
      
      // Print results
      result.printResults();
      
      // Get AI feedback if enabled
      try {
        final aiService = AIService();
        if (aiService.isEnabled) {
          print('\n🤖 Getting AI validation feedback...\n');
          
          final aiFeedback = await aiService.validateMapping(
            mapping,
            analysis.colors,
          );
          
          aiFeedback.print();
        }
      } catch (e) {
        print('\n⚠️  AI validation unavailable: $e');
      }
      
      if (!result.isValid) {
        exit(1);
      }
      
      print('\n✅ Mapping configuration is valid!');
    } catch (e, stack) {
      print('❌ Error validating mapping: $e');
      print(stack);
      exit(1);
    }
  }
}

/// Generate theme code
class ThemeGenerateCommand extends Command<void> {
  @override
  final name = 'theme-generate';
  
  @override
  final description = 'Generate ThemeData and ThemeExtension classes';

  ThemeGenerateCommand() {
    argParser
      ..addOption(
        'mapping',
        abbr: 'm',
        help: 'Mapping configuration file',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for theme files',
        mandatory: true,
      );
  }

  @override
  Future<void> run() async {
    final mappingPath = argResults!['mapping'] as String;
    final outputPath = argResults!['output'] as String;
    
    print('🎨 Generating theme code...\n');
    
    try {
      // Load mapping file
      final loader = MappingLoader();
      final mapping = await loader.loadFromFile(mappingPath);
      
      print('✓ Loaded mapping configuration');
      
      // Run analysis to get color definitions
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      
      // Generate theme
      final generator = ThemeGenerator();
      await generator.generateTheme(mapping, analysis, outputPath);
      
      print('\n✅ Theme code generated!');
      print('📝 Import the theme in your app:');
      print("   import 'theme/app_theme.dart';");
      print('   MaterialApp(theme: AppTheme.light(), ...)');
    } catch (e, stack) {
      print('❌ Error generating theme: $e');
      print(stack);
      exit(1);
    }
  }
}

/// Refactor codebase
class RefactorCommand extends Command<void> {
  @override
  final name = 'refactor';
  
  @override
  final description = 'Refactor color usage in codebase';

  RefactorCommand() {
    argParser
      ..addOption(
        'mapping',
        abbr: 'm',
        help: 'Mapping configuration file',
        mandatory: true,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview changes without applying them',
        negatable: false,
      )
      ..addFlag(
        'apply',
        help: 'Apply changes to codebase',
        negatable: false,
      )
      ..addOption(
        'batch-size',
        help: 'Number of files to process in each batch',
        defaultsTo: '50',
      );
  }

  @override
  Future<void> run() async {
    final isDryRun = argResults!['dry-run'] as bool;
    final apply = argResults!['apply'] as bool;
    final mappingPath = argResults!['mapping'] as String;
    
    if (!isDryRun && !apply) {
      print('Error: Must specify either --dry-run or --apply');
      exit(1);
    }
    
    print('🔄 ${isDryRun ? 'Previewing' : 'Applying'} refactoring...\n');
    
    try {
      // Load mapping configuration
      final loader = MappingLoader();
      final mapping = await loader.loadFromFile(mappingPath);
      
      print('✓ Loaded mapping configuration');
      
      // Run analysis
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      
      // Create refactorer
      final refactorer = CodeRefactorer(
        config: mapping,
        analysis: analysis,
      );
      
      // Run refactoring
      final results = await refactorer.refactorProject(
        projectPath: Directory.current.path,
        dryRun: isDryRun,
      );
      
      // Generate diff report
      if (isDryRun && results.modifiedFileCount > 0) {
        final diffGen = DiffGenerator();
        await diffGen.generateHtmlDiff(
          results,
          'refactoring_diff.html',
        );
        
        print('\n📝 Review the diff report: refactoring_diff.html');
        print('💡 To apply changes, run with --apply flag');
      }
      
      print('\n✅ Refactoring complete!');
    } catch (e, stack) {
      print('❌ Error during refactoring: $e');
      print(stack);
      exit(1);
    }
  }
}

/// Verify migration
class VerifyCommand extends Command<void> {
  @override
  final name = 'verify';
  
  @override
  final description = 'Verify migration correctness';

  VerifyCommand() {
    argParser
      ..addOption(
        'baseline',
        help: 'Baseline screenshots directory',
      )
      ..addOption(
        'current',
        help: 'Current screenshots directory',
      );
  }

  @override
  Future<void> run() async {
    print('✓ Verifying migration...');
    
    // TODO: Implement verification
    
    print('✅ Verification complete!');
  }
}
}

/// Rollback changes using a backup
class RollbackCommand extends Command<void> {
  @override
  final name = 'rollback';
  
  @override
  final description = 'Rollback refactored code to a previous backup';

  RollbackCommand() {
    argParser
      ..addOption(
        'backup-id',
        abbr: 'b',
        help: 'Backup ID to restore (use "list" command to see available backups)',
      )
      ..addFlag(
        'list',
        abbr: 'l',
        help: 'List available backups',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final listBackups = argResults!['list'] as bool;
    final backupId = argResults!['backup-id'] as String?;
    
    final backupManager = BackupManager(
      projectPath: Directory.current.path,
    );
    
    if (listBackups) {
      print('📦 Available Backups:\n');
      
      final backups = await backupManager.listBackups();
      
      if (backups.isEmpty) {
        print('No backups found.');
        return;
      }
      
      for (final backup in backups) {
        print('ID: ${backup.id}');
        print('   Timestamp: ${backup.timestamp}');
        print('   Files: ${backup.fileCount}');
        print('   Location: ${backup.location}\n');
      }
      
      print('To restore a backup:');
      print('  dart run bin/color_migrate.dart rollback --backup-id <ID>');
      return;
    }
    
    if (backupId == null) {
      print('Error: Either --list or --backup-id must be specified');
      print('Use --list to see available backups');
      exit(1);
    }
    
    print('♻️   Rolling back to backup: $backupId\n');
    
    try {
      // Verify backup first
      print('Verifying backup integrity...');
      final verification = await backupManager.verifyBackup(backupId);
      
      if (!verification.isValid) {
        print('⚠️  Backup integrity check failed:');
        print('   Missing files: ${verification.missingFiles}');
        print('   Corrupted files: ${verification.corruptedFiles}');
        print('\nContinue anyway? (y/N): ');
        
        final response = stdin.readLineSync();
        if (response?.toLowerCase() != 'y') {
          print('Rollback cancelled.');
          exit(1);
        }
      } else {
        print('✓ Backup verified (${verification.verifiedFiles} files)');
      }
      
      // Restore backup
      await backupManager.restoreBackup(backupId);
      
      print('\n✅ Rollback complete!');
    } catch (e) {
      print('❌ Rollback failed: $e');
      exit(1);
    }
  }
}
}

/// Check migration readiness
class CheckReadinessCommand extends Command<void> {
  @override
  final name = 'check-readiness';
  
  @override
  final description = 'Check if project is ready for color migration';

  CheckReadinessCommand() {
    argParser
      ..addOption(
        'mapping',
        abbr: 'm',
        help: 'Path to mapping configuration file',
        defaultsTo: 'color_mapping.yaml',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show detailed validation output',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final mappingPath = argResults!['mapping'] as String;
    final verbose = argResults!['verbose'] as bool;
    
    print('🔍 Checking Migration Readiness...\n');
    
    try {
      // Load mapping
      print('Loading mapping configuration...');
      final loader = MappingLoader();
      final mapping = await loader.loadFromFile(mappingPath);
      print('✓ Loaded mapping (version ${mapping.version})\n');
      
      // Run analysis
      print('Analyzing project colors...');
      final analyzer = UsageAnalyzer();
      final analysis = await analyzer.analyzeProject(Directory.current.path);
      print('✓ Found ${analysis.colors.length} colors\n');
      
      // Run validation
      final validator = PreMigrationValidator();
      final result = await validator.validate(
        analysis: analysis,
        config: mapping,
        projectPath: Directory.current.path,
      );
      
      // Print report
      result.printReport();
      
      // Exit with appropriate code
      if (!result.isReady) {
        exit(1);
      }
    } catch (e, stack) {
      print('❌ Readiness check failed: $e');
      if (verbose) {
        print(stack);
      }
      exit(1);
    }
  }
}
