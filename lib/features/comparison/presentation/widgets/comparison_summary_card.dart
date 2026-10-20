import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/forensic_card.dart';
import '../../models/comparison_models.dart';

class ComparisonSummaryCard extends StatelessWidget {
  final ComparisonSummary summary;
  final VoidCallback onDownloadReport;
  final bool isDownloadingReport;

  const ComparisonSummaryCard({
    super.key,
    required this.summary,
    required this.onDownloadReport,
    this.isDownloadingReport = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = summary.overallSimilarityPercentage;
    final sev = summary.severity;

    final Color statusColor = sev == 'NONE'
        ? AppColors.successGreen
        : (sev == 'LOW' || sev == 'MEDIUM' ? AppColors.warningOrange : AppColors.errorRed);

    return ForensicCard(
      borderColor: statusColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Verdict Badge and Export PDF Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      summary.verdictLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Export PDF Report Button
              ElevatedButton.icon(
                icon: isDownloadingReport
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: isDownloadingReport ? null : onDownloadReport,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Overall Visual Similarity Section (Full Width)
          Text(
            'Overall Visual Similarity',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: statusColor,
                ),
              ),
              Text(
                '(${summary.totalSuspiciousIntervals} suspicious interval${summary.totalSuspiciousIntervals == 1 ? "" : "s"})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Forensic Metrics Grid (Responsive 2x2 on mobile, 1x4 on tablet/desktop)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;
              final tile1 = _buildMetricTile(
                'Avg SSIM Index',
                summary.averageSsim.toStringAsFixed(3),
                'Structural consistency (1.0 = match)',
                summary.averageSsim >= 0.85 ? AppColors.successGreen : AppColors.warningOrange,
              );
              final tile2 = _buildMetricTile(
                'Mean Pixel Error (MAE)',
                summary.averageMae.toStringAsFixed(3),
                'Normalized distance (0.0 = match)',
                summary.averageMae <= 0.05 ? AppColors.successGreen : AppColors.warningOrange,
              );
              final tile3 = _buildMetricTile(
                'pHash Distance',
                summary.averagePhashDistance.toStringAsFixed(3),
                'Gradient hash (0.0 = match)',
                summary.averagePhashDistance <= 0.10 ? AppColors.successGreen : AppColors.warningOrange,
              );
              final tile4 = _buildMetricTile(
                'Overlap Duration',
                '${summary.overlapDuration.toStringAsFixed(1)}s',
                '${summary.totalSamplesAnalyzed} aligned sample frames',
                AppColors.primaryAccent,
              );

              if (isWide) {
                return Row(
                  children: [
                    tile1,
                    const SizedBox(width: 8),
                    tile2,
                    const SizedBox(width: 8),
                    tile3,
                    const SizedBox(width: 8),
                    tile4,
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        tile1,
                        const SizedBox(width: 8),
                        tile2,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        tile3,
                        const SizedBox(width: 8),
                        tile4,
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
