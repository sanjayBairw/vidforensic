import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  final String confidence;
  final bool compact;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.compact = false,
  });

  Color _getBadgeColor(BuildContext context) {
    final upper = confidence.toUpperCase();
    if (upper == 'HIGH') {
      return AppColors.highConfidence;
    } else if (upper == 'MEDIUM') {
      return AppColors.mediumConfidence;
    } else if (upper == 'LOW') {
      return AppColors.lowConfidence;
    } else {
      return AppColors.neutralConfidence;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor(context);
    final upper = confidence.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        upper.isEmpty ? 'NONE' : upper,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
