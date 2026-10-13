import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum StageStatus { waiting, processing, completed, failed }

class StatusIndicator extends StatelessWidget {
  final String title;
  final StageStatus status;
  final String? subtitle;

  const StatusIndicator({
    super.key,
    required this.title,
    required this.status,
    this.subtitle,
  });

  Widget _buildIcon(BuildContext context) {
    switch (status) {
      case StageStatus.waiting:
        return const Icon(Icons.circle_outlined, color: Colors.grey, size: 20);
      case StageStatus.processing:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      case StageStatus.completed:
        return const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 20);
      case StageStatus.failed:
        return const Icon(Icons.cancel, color: AppColors.statusError, size: 20);
    }
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case StageStatus.waiting:
        return isDark ? Colors.grey[500]! : Colors.grey[600]!;
      case StageStatus.processing:
        return Theme.of(context).colorScheme.primary;
      case StageStatus.completed:
        return isDark ? Colors.white : Colors.black87;
      case StageStatus.failed:
        return AppColors.statusError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildIcon(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: status == StageStatus.processing ? FontWeight.bold : FontWeight.w500,
                    color: _getTextColor(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
