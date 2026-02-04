# AI-Assisted Color System Migration Tool

Automatically migrate Flutter apps from hardcoded color constants to Material 3 ThemeData with proper ColorScheme and ThemeExtensions.

## Features

- 🔍 **Automatic Color Detection** - Scans your entire codebase for color definitions and usages
- 🎨 **Smart Classification** - Categorizes colors into primary, secondary, semantic, brand, and component groups
- 🤖 **AI-Powered Suggestions** - Optional AI assistance for optimal color mappings
- 🛡️ **Safe Refactoring** - Automatic backups, dry-run mode, and rollback support
- ✅ **Migration Validation** - Pre-migration readiness checks ensure smooth transitions
- 📊 **Visual Diff Viewer** - HTML-based diff preview before applying changes

## Quick Start

```bash
# 1. Navigate to your Flutter project
cd /path/to/your/flutter/project

# 2. Run audit
dart run /path/to/color_migration_tool/bin/color_migrate.dart audit

# 3. Classify colors
dart run /path/to/color_migration_tool/bin/color_migrate.dart classify -a audit.json -o classification.json

# 4. Generate mapping
dart run /path/to/color_migration_tool/bin/color_migrate.dart map-generate -c classification.json -o color_mapping.yaml

# 5. Check readiness
dart run /path/to/color_migration_tool/bin/color_migrate.dart check-readiness -m color_mapping.yaml

# 6. Preview changes
dart run /path/to/color_migration_tool/bin/color_migrate.dart refactor -m color_mapping.yaml --dry-run

# 7. Apply migration
dart run /path/to/color_migration_tool/bin/color_migrate.dart refactor -m color_mapping.yaml --apply
```

## Documentation

- **[User Guide](USER_GUIDE.md)** - Complete usage documentation
- **[Testing Guide](../brain/*/testing_guide.md)** - How to test with example_app
- **[Implementation Plans](../brain/*/implementation_plan.md)** - Technical details

## Commands

| Command | Purpose |
|---------|---------|
| `audit` | Scan project for all color definitions and usages |
| `classify` | Categorize colors by semantic role |
| `map-generate` | Create mapping configuration from classification |
| `map-suggest` | Get AI suggestions for color mappings (optional) |
| `map-validate` | Validate mapping configuration |
| `check-readiness` | Verify project is ready for migration |
| `theme-generate` | Generate ThemeData code from mapping |
| `refactor` | Apply code refactoring (with --dry-run or --apply) |
| `rollback` | Restore from backup if needed |

## Requirements

- Dart SDK 3.0+ or Flutter 3.10+
- A Flutter project with color constants to migrate

## Installation

```bash
git clone https://github.com/YOUR_REPO/AI-Assisted-Color-System-Migration-Flutter.git
cd AI-Assisted-Color-System-Migration-Flutter/color_migration_tool
dart pub get
```

## Example Output

**Before Migration:**
```dart
class AppColors {
  static const primaryBlue = Color(0xFF1976D2);
  static const errorRed = Color(0xFFD32F2F);
}

// Usage
Container(color: AppColors.primaryBlue)
```

**After Migration:**
```dart
// Generated theme
final theme = ThemeData(
  colorScheme: ColorScheme(
    primary: Color(0xFF1976D2),
    error: Color(0xFFD32F2F),
  ),
);

// Updated usage
Container(color: Theme.of(context).colorScheme.primary)
```

## Benefits

✅ **Material 3 Compliance** - Modern Flutter theming  
✅ **Dark Mode Support** - Built-in light/dark theme support  
✅ **Type Safety** - Compile-time color checking  
✅ **Maintainability** - Centralized theme management  
✅ **Customization** - Easy widget-level theme overrides

## License

MIT License - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_REPO/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_REPO/discussions)
