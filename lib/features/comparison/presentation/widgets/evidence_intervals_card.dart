import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/forensic_card.dart';
import '../../models/comparison_models.dart';

class EvidenceIntervalsCard extends StatelessWidget {
  final List<SuspiciousInterval> intervals;
  final String? evidenceBaseUrl;
  final int? selectedIntervalIndex;
  final Function(SuspiciousInterval interval) onSelectInterval;

  const EvidenceIntervalsCard({
    super.key,
    required this.intervals,
    required this.evidenceBaseUrl,
    required this.selectedIntervalIndex,
    required this.onSelectInterval,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ForensicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library_outlined, color: AppColors.primaryAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'SUSPICIOUS INTERVALS & EVIDENCE PLATES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              Text(
                '${intervals.length} Items',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (intervals.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 40, color: AppColors.successGreen),
                  const SizedBox(height: 8),
                  const Text(
                    'No Suspicious Discrepancies Detected',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Both videos demonstrate high structural and perceptual continuity across all aligned frames.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...intervals.map((it) => _buildIntervalItem(context, it, theme)),
        ],
      ),
    );
  }

  Widget _buildIntervalItem(
      BuildContext context, SuspiciousInterval it, ThemeData theme) {
    final isSelected = it.intervalIndex == selectedIntervalIndex;
    final sevColor = it.severity == 'SIGNIFICANT'
        ? AppColors.errorRed
        : (it.severity == 'MODERATE' ? AppColors.warningOrange : Colors.amber);

    final plateFilename = it.evidenceFiles['composite_plate'];
    final plateUrl = (evidenceBaseUrl != null && plateFilename != null)
        ? '$evidenceBaseUrl/$plateFilename'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.08)
            : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primaryAccent : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interval Header Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: sevColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    it.intervalId,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: sevColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ref: ${it.startTimeA.toStringAsFixed(2)}s - ${it.endTimeA.toStringAsFixed(2)}s  |  Susp: ${it.startTimeB.toStringAsFixed(2)}s - ${it.endTimeB.toStringAsFixed(2)}s',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Min SSIM: ${it.minSsim.toStringAsFixed(3)}  •  Max Diff: ${it.maxDifference.toStringAsFixed(3)}  •  Duration: ${it.duration.toStringAsFixed(2)}s',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Seek Player', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? AppColors.primaryAccent : Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => onSelectInterval(it),
                ),
              ],
            ),
          ),

          // Evidence Image Plate (Composite: Ref | Susp | Diff Heatmap)
          if (plateUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Stack(
                children: [
                  Image.network(
                    plateUrl,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: Text(
                        'Evidence plate generated: ${it.evidenceFiles['composite_plate']}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Factual description footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              it.explanation,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
