import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Color Migration Demo'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Example Application',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This app demonstrates various color usages that will be migrated',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Status badges
            const Text(
              'Status Indicators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                StatusBadge(label: 'Success', type: BadgeType.success),
                StatusBadge(label: 'Warning', type: BadgeType.warning),
                StatusBadge(label: 'Error', type: BadgeType.error),
                StatusBadge(label: 'Info', type: BadgeType.info),
              ],
            ),
            const SizedBox(height: 24),
            
            // Buttons
            const Text(
              'Button Styles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CustomButton(
                  label: 'Primary Action',
                  backgroundColor: AppColors.buttonPrimary,
                  onPressed: () {},
                ),
                CustomButton(
                  label: 'Secondary Action',
                  backgroundColor: AppColors.buttonSecondary,
                  onPressed: () {},
                ),
                CustomButton(
                  label: 'Disabled',
                  backgroundColor: AppColors.buttonDisabled,
                  onPressed: null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Cards
            const Text(
              'Card Components',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              title: 'Feature Card 1',
              description: 'This card uses multiple color constants',
              iconColor: AppColors.blue500,
            ),
            const SizedBox(height: 12),
            CustomCard(
              title: 'Feature Card 2',
              description: 'Each card demonstrates color usage',
              iconColor: AppColors.green500,
            ),
            const SizedBox(height: 12),
            CustomCard(
              title: 'Feature Card 3',
              description: 'These will be migrated to theme colors',
              iconColor: AppColors.orange500,
            ),
            const SizedBox(height: 24),
            
            // Color palette showcase
            const Text(
              'Color Palette Reference',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildColorRow('Blue Shades', [
              AppColors.blue50,
              AppColors.blue100,
              AppColors.blue200,
              AppColors.blue300,
              AppColors.blue400,
              AppColors.blue500,
              AppColors.blue600,
              AppColors.blue700,
              AppColors.blue800,
              AppColors.blue900,
            ]),
            const SizedBox(height: 8),
            _buildColorRow('Green Shades', [
              AppColors.green50,
              AppColors.green100,
              AppColors.green200,
              AppColors.green300,
              AppColors.green400,
              AppColors.green500,
              AppColors.green600,
              AppColors.green700,
              AppColors.green800,
              AppColors.green900,
            ]),
            const SizedBox(height: 8),
            _buildColorRow('Grey Shades', [
              AppColors.grey50,
              AppColors.grey100,
              AppColors.grey200,
              AppColors.grey300,
              AppColors.grey400,
              AppColors.grey500,
              AppColors.grey600,
              AppColors.grey700,
              AppColors.grey800,
              AppColors.grey900,
            ]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorRow(String label, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: colors.map((color) {
            return Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: AppColors.divider,
                    width: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
