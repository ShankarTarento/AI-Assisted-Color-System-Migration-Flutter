# Color Migration Tool

AI-assisted Flutter color system migration tool that safely migrates large Flutter applications from color constants to semantic theming.

## Features

- 🔍 **Static Analysis** - Audit all color usage in your Flutter project
- 🏷️ **Classification** - Automatically categorize colors (core, variant, component, legacy, unused)
- 🗺️ **Mapping Configuration** - Explicit YAML-based color mapping (no guessing)
- 🎨 **Theme Generation** - Generate `ThemeData` and `ThemeExtension` classes
- 🔄 **Safe Refactoring** - AST-based code transformation with context injection
- 🤖 **AI Assistance** - LLM-powered mapping suggestions and safety validation
- ✅ **Zero Regressions** - Verified through golden tests and explicit mappings

## Installation

```bash
# Clone the repository
git clone <repo-url>
cd color_migration_tool

# Install dependencies
dart pub get

# Compile the executable
dart compile exe bin/color_migrate.dart -o color_migrate

# Add to PATH (optional)
export PATH="$PATH:$(pwd)"
```

## Quick Start

```bash
# 1. Initialize migration project
color_migrate init --project /path/to/your/flutter/app

# 2. Run color audit
color_migrate audit --output audit_report.json

# 3. Classify colors
color_migrate classify --audit audit_report.json --output classification.json

# 4. Generate mapping template
color_migrate map-generate --classification classification.json --output color_mapping.yaml

# 5. (Optional) AI-assisted suggestions
color_migrate map-suggest --audit audit_report.json --ai-provider openai

# 6. Validate mapping
color_migrate map-validate --mapping color_mapping.yaml

# 7. Generate theme code
color_migrate theme-generate --mapping color_mapping.yaml --output lib/theme/

# 8. Preview changes (dry-run)
color_migrate refactor --mapping color_mapping.yaml --dry-run

# 9. Apply refactoring
color_migrate refactor --mapping color_mapping.yaml --apply

# 10. Verify migration
color_migrate verify --baseline screenshots/baseline/ --current screenshots/current/
```

## Configuration

Create `.color_migrate.yaml` in your project root:

```yaml
project_root: /path/to/flutter/app
color_class: lib/constants/app_colors.dart
theme_output: lib/theme/
backup_dir: .migration_backup/

ai_config:
  provider: openai
  model: gpt-4
  api_key_env: OPENAI_API_KEY

safety:
  require_approval: true
  create_backup: true
  max_files_per_batch: 50
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Mapping Configuration Reference](docs/mapping_config.md)
- [Migration Guide](docs/migration_guide.md)
- [API Documentation](docs/api.md)

## Development

```bash
# Run tests
dart test

# Run with debugging
dart run bin/color_migrate.dart audit --project ../example_app

# Format code
dart format .

# Analyze code
dart analyze
```

## License

MIT License - See LICENSE file for details
