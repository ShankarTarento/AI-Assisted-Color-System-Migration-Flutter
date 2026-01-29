import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum BadgeType { success, warning, error, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  Color get backgroundColor {
    switch (type) {
      case BadgeType.success:
        return AppColors.successGreen;
      case BadgeType.warning:
        return AppColors.warningYellow;
      case BadgeType.error:
        return AppColors.errorRed;
      case BadgeType.info:
        return AppColors.infoBlue;
    }
  }

  Color get textColor {
    switch (type) {
      case BadgeType.success:
      case BadgeType.error:
      case BadgeType.info:
        return AppColors.textOnPrimary;
      case BadgeType.warning:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
