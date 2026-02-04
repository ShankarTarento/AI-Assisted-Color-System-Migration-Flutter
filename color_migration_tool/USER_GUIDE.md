# AI-Assisted Color System Migration Tool

**Automatically migrate Flutter apps from color constants to Material 3 ThemeData**

---

## What It Does

This tool helps you modernize your Flutter app's color system by:
- **Analyzing** all color definitions and usages in your codebase
- **Classifying** colors into semantic categories (primary, secondary, semantic, brand, etc.)
- **Generating** Material 3 `ThemeData` with proper `ColorScheme` and `ThemeExtension`s
- **Refactoring** code to use `Theme.of(context)` instead of hardcoded colors
- **Validating** migration readiness before making changes

**Benefits:**
- ✅ Material 3 compliant theming
- ✅ Support for light/dark modes
- ✅ Better widget customization
- ✅ Reduced code duplication
- ✅ Safe, reversible migrations with automatic backups

---

## Installation

### Prerequisites
- Dart SDK 3.0+ or Flutter 3.10+
- A Flutter project with color constants to migrate

### Setup

1. **Clone the repository:**
```bash
git clone https://github.com/YOUR_REPO/AI-Assisted-Color-System-Migration-Flutter.git
cd AI-Assisted-Color-System-Migration-Flutter/color_migration_tool
```

2. **Install dependencies:**
```bash
dart pub get
```

3. **Optional: Enable AI features**
```bash
cp .env.example .env
# Edit .env and add your Gemini API key
```

---

## Quick Start

Navigate to your Flutter project and run:

```bash
cd /path/to/your/flutter/project

# Step 1: Audit colors
dart run /path/to/color_migration_tool/bin/color_migrate.dart audit

# Step 2: Classify colors
dart run /path/to/color_migration_tool/bin/color_migrate.dart classify \
  -a audit.json -o classification.json

# Step 3: Generate mapping
dart run /path/to/color_migration_tool/bin/color_migrate.dart map-generate \
  -c classification.json -o color_mapping.yaml

# Step 4: Check readiness
dart run /path/to/color_migration_tool/bin/color_migrate.dart check-readiness \
  -m color_mapping.yaml

# Step 5: Preview changes (dry-run)
dart run /path/to/color_migration_tool/bin/color_migrate.dart refactor \
  -m color_mapping.yaml --dry-run

# Step 6: Apply changes
dart run /path/to/color_migration_tool/bin/color_migrate.dart refactor \
  -m color_mapping.yaml --apply
```

---

## Commands Reference

### `audit` - Scan for Colors

**Purpose:** Find all color definitions and usages in your project

**Usage:**
```bash
dart run color_migrate.dart audit [options]
```

**Options:**
- `-o, --output <file>` - Output file (default: `audit.json`)

**What it does:**
- Scans all `.dart` files
- Finds `Color` constants (e.g., `Color(0xFFRRGGBB)`, `Color.fromRGBO()`)
- Tracks where each color is used
- Generates usage statistics

**Output:** `audit.json`
```json
{
  "totalFiles": 25,
  "uniqueColors": 150,
  "colorDefinitions": [...],
  "colorUsages": [...],
  "usageStats": {...}
}
```

---

### `classify` - Categorize Colors

**Purpose:** Automatically categorize colors by their role

**Usage:**
```bash
dart run color_migrate.dart classify -a <audit-file> -o <output-file>
```

**Options:**
- `-a, --audit <file>` - Input audit file (required)
- `-o, --output <file>` - Output file (default: `classification.json`)

**Color Categories:**
- **Primary** → `ColorScheme.primary`
- **Secondary** → `ColorScheme.secondary`
- **Semantic** → `ColorScheme.error`, `ColorScheme.tertiary`, etc.
- **Brand** → `ThemeExtension` (BrandColors)
- **Neutral** → Surface/background colors
- **Component** → UI component-specific colors

**Output:** `classification.json`

---

### `map-generate` - Create Mapping Config

**Purpose:** Generate YAML configuration for color mappings

**Usage:**
```bash
dart run color_migrate.dart map-generate -c <classification-file> -o <output-file>
```

**Options:**
- `-c, --classification <file>` - Input classification file (required)
- `-o, --output <file>` - Output file (default: `color_mapping.yaml`)

**Output:** `color_mapping.yaml`
```yaml
version: "1.0.0"

strictMappings:
  AppColors.primaryBlue:
    target: colorScheme.primary
  AppColors.errorRed:
    target: colorScheme.error

extensions:
  BrandColors:
    colors:
      AppColors.blue500:
        target: blue500
        value: '0xFF2196F3'

preserved:
  - AppColors.legacyColor
```

**Editing the mapping:**
You can manually edit `color_mapping.yaml` to:
- Change color mappings
- Add/remove ThemeExtensions
- Mark colors as preserved (unchanged)

---

### `check-readiness` - Validate Migration

**Purpose:** Check if your project is ready for migration

**Usage:**
```bash
dart run color_migrate.dart check-readiness -m <mapping-file>
```

**Options:**
- `-m, --mapping <file>` - Mapping configuration (default: `color_mapping.yaml`)
- `-v, --verbose` - Show detailed output

**What it checks:**
1. **Unmapped Colors**
   - 🔴 Critical: High usage (≥10 times)
   - 🟡 Warning: Medium usage (3-9 times)
   - 🔵 Info: Low usage (<3 times)

2. **Theme Completeness**
   - Essential `ColorScheme` properties present
   - Valid extension names
   - No naming conflicts

3. **File Permissions**
   - All files are writable

**Exit codes:**
- `0` - Ready to proceed
- `1` - Errors found, not ready

---

### `theme-generate` - Generate Theme Code

**Purpose:** Create ThemeData code from mapping

**Usage:**
```bash
dart run color_migrate.dart theme-generate -m <mapping-file> -o <output-file>
```

**Options:**
- `-m, --mapping <file>` - Mapping configuration (required)
- `-o, --output <file>` - Output Dart file (required)

**Output:** Generated Dart file with:
- `ColorScheme` for light/dark themes
- `ThemeExtension` classes for color groups
- Helper methods for easy access

**Example:**
```dart
final theme = ThemeData(
  colorScheme: ColorScheme(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF388E3C),
    error: Color(0xFFD32F2F),
    // ... more properties
  ),
  extensions: [
    BrandColors(
      blue500: Color(0xFF2196F3),
      green500: Color(0xFF4CAF50),
      // ...
    ),
  ],
);
```

---

### `refactor` - Apply Code Changes

**Purpose:** Replace color constants with theme references

**Usage:**
```bash
dart run color_migrate.dart refactor -m <mapping-file> [--dry-run | --apply]
```

**Options:**
- `-m, --mapping <file>` - Mapping configuration (required)
- `--dry-run` - Preview changes without modifying files (default)
- `--apply` - Actually modify files (creates backup first)

**What it does:**
1. Creates backup in `.color_migrate_backups/`
2. Replaces color constants:
   - `AppColors.primary` → `Theme.of(context).colorScheme.primary`
   - `AppColors.blue500` → `Theme.of(context).extension<BrandColors>()!.blue500`
3. Generates HTML diff viewer (`refactoring_diff.html`)

**Safety features:**
- ✅ Automatic backups with SHA-256 verification
- ✅ BuildContext availability checking
- ✅ Dry-run preview before changes
- ✅ Syntax validation

---

### `rollback` - Undo Changes

**Purpose:** Restore files from backup

**Usage:**
```bash
# List backups
dart run color_migrate.dart rollback --list

# Restore specific backup
dart run color_migrate.dart rollback --id <backup-id>
```

**Options:**
- `--list` - Show available backups
- `--id <id>` - Backup ID to restore

**Features:**
- Verifies backup integrity before restoring
- Prompts for confirmation
- Restores all files to previous state

---

## Complete Workflow Example

### Scenario: Migrating a 200-color Flutter App

**1. Initial Audit**
```bash
cd myapp
dart run ../color_migration_tool/bin/color_migrate.dart audit
```
**Output:**
```
🔍 Scanning project for color definitions...
Found 200 colors in 3 files
Analyzing color usages...

📊 Color Audit Summary
━━━━━━━━━━━━━━━━━━━
Total Files Scanned:    45
Unique Colors Found:    200
Total Color Usages:     1,234
Average Usage per Color: 6
```

**2. Classify Colors**
```bash
dart run ../color_migration_tool/bin/color_migrate.dart classify \
  -a audit.json -o classification.json
```
**Output:**
```
📊 Color Classification Summary
━━━━━━━━━━━━━━━━━━━━━━━━
Primary Colors:    8 colors
Secondary Colors:  5 colors
Semantic Colors:   12 colors
Brand Colors:      3 colors
Neutral Colors:    10 colors
Component Colors:  162 colors
```

**3. Generate Mapping**
```bash
dart run ../color_migration_tool/bin/color_migrate.dart map-generate \
  -c classification.json -o color_mapping.yaml
```

**4. Review & Edit Mapping**
```bash
# Open and edit color_mapping.yaml
nano color_mapping.yaml

# Adjust mappings as needed:
# - Move colors between categories
# - Add preserved colors
# - Customize extension names
```

**5. Check Readiness**
```bash
dart run ../color_migration_tool/bin/color_migrate.dart check-readiness \
  -m color_mapping.yaml
```
**Output:**
```
============================================================
📊 Pre-Migration Validation Report
============================================================

📋 Unmapped Colors Report:
   Total: 5 colors

🟡 Warning (Medium Usage): 3 colors
   AppColors.oldAccent (0xFF00BCD4) - Used 5 times

🔵 Info (Low Usage): 2 colors
   AppColors.unused1 (0xFF795548) - Used 1 times

🎨 Theme Validation:
✅ All essential properties mapped

============================================================
🎯 Migration Readiness: ⚠️  READY WITH WARNINGS
============================================================

💡 Recommendation:
   • Migration can proceed, but review warnings first.
   • 5 unmapped colors will remain unchanged.
```

**6. Generate Theme**
```bash
dart run ../color_migration_tool/bin/color_migrate.dart theme-generate \
  -m color_mapping.yaml -o lib/theme/app_theme.dart
```

**7. Preview Changes**
```bash
dart run ../color_migration_tool/bin/color_migrate.dart refactor \
  -m color_mapping.yaml --dry-run
```
**Output:**
```
🔄 Previewing refactoring...

  📝 lib/widgets/custom_button.dart: 8 changes
  📝 lib/widgets/custom_card.dart: 5 changes
  📝 lib/screens/home_screen.dart: 12 changes

📊 Refactoring Summary:
  Files scanned: 45
  Files modified: 28
  Total changes: 156

✅ Diff saved to: refactoring_diff.html
```

**8. Review HTML Diff**
```bash
# Open in browser
xdg-open refactoring_diff.html
```

**9. Apply Changes**
```bash
# Commit current state first
git add . && git commit -m "Before color migration"

# Apply refactoring
dart run ../color_migration_tool/bin/color_migrate.dart refactor \
  -m color_mapping.yaml --apply
```
**Output:**
```
🔄 Applying refactoring...

Creating backup...
✓ Backup created: backup_20260202_133045

Refactoring files...
  ✓ lib/widgets/custom_button.dart: 8 changes
  ✓ lib/widgets/custom_card.dart: 5 changes
  ...

✅ Refactoring complete!

📊 Summary:
  Files modified: 28
  Total changes: 156
  Backup ID: backup_20260202_133045
```

**10. Test & Rollback if Needed**
```bash
# Run your app
flutter run

# If issues occur, rollback:
dart run ../color_migration_tool/bin/color_migrate.dart rollback \
  --id backup_20260202_133045
```

---

## AI Features (Optional)

Enable AI-powered suggestions by setting up your `.env` file:

### Setup
```bash
cp .env.example .env
```

Edit `.env`:
```
ENABLE_AI_SUGGESTIONS=true
GEMINI_API_KEY=your_api_key_here
AI_MODEL=gemini-pro
CONFIDENCE_THRESHOLD=0.7
```

### AI Commands

**Get AI Mapping Suggestions:**
```bash
dart run color_migrate.dart map-suggest -a audit.json
```

**Get AI Validation Feedback:**
```bash
dart run color_migrate.dart map-validate -m color_mapping.yaml --ai
```

---

## Troubleshooting

### No colors found during audit
**Problem:** Audit reports 0 colors  
**Solution:**
- Ensure you're in the Flutter project root
- Check that color constants are defined as `static const Color`
- Verify files use standard Flutter color definitions

### Too many unmapped colors
**Problem:** check-readiness shows many unmapped colors  
**Solution:**
- Edit `color_mapping.yaml` to add mappings
- Add unused colors to `preserved` list
- Re-run `check-readiness`

### BuildContext not available errors
**Problem:** Refactoring shows BuildContext errors  
**Solution:**
- These require manual intervention
- Check `refactoring_diff.html` for flagged locations
- Options:
  - Pass `BuildContext` as parameter
  - Use `Builder` widget
  - Keep as constant for `const` widgets

### Backup verification failed
**Problem:** Rollback shows integrity errors  
**Solution:**
- Files may have been modified after backup
- Review changes manually
- Use git to restore if needed

---

## Best Practices

### Before Migration
1. ✅ **Commit your code** - Always have a clean git state
2. ✅ **Run tests** - Ensure everything works before migration
3. ✅ **Review mapping** - Don't blindly accept generated mappings
4. ✅ **Start with dry-run** - Always preview changes first

### During Migration
1. ✅ **Check readiness** - Fix errors before applying
2. ✅ **Review diff HTML** - Understand what will change
3. ✅ **Note backup ID** - Save for potential rollback

### After Migration
1. ✅ **Run tests** - Verify functionality
2. ✅ **Check UI** - Visual regression testing
3. ✅ **Review manual fixes** - Address BuildContext issues
4. ✅ **Update theme usage** - Use generated theme in `MaterialApp`

---

## FAQ

**Q: Will this work with my existing theme?**  
A: Yes! The tool generates a new theme structure. You'll need to integrate it with your existing `ThemeData`.

**Q: Can I customize the mappings?**  
A: Absolutely! Edit `color_mapping.yaml` to adjust any mappings before refactoring.

**Q: Is this safe? What if something breaks?**  
A: Very safe! The tool:
- Creates automatic backups
- Supports rollback
- Has dry-run mode
- Validates before applying

**Q: How long does migration take?**  
A: For a typical app:
- Audit: <5 seconds
- Classification: <2 seconds
- Refactoring: <30 seconds
- Manual review: 15-60 minutes

**Q: Do I need an AI API key?**  
A: No! AI features are optional. The tool works perfectly without AI.

**Q: Will it handle dark mode?**  
A: The generated `ColorScheme` supports both light and dark modes. You'll need to define dark mode color values in the mapping.

**Q: Can I migrate incrementally?**  
A: Yes! Use the `preserved` list in `color_mapping.yaml` to keep some colors unchanged.

---

## Support & Contributing

**Issues:** [GitHub Issues](https://github.com/YOUR_REPO/issues)  
**Discussions:** [GitHub Discussions](https://github.com/YOUR_REPO/discussions)

---

## License

MIT License - See LICENSE file for details
