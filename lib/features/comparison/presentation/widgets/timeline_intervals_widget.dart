import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/forensic_card.dart';
import '../../models/comparison_models.dart';

class TimelineIntervalsWidget extends StatelessWidget {
  final double totalDuration;
  final List<SuspiciousInterval> intervals;
  final int? selectedIntervalIndex;
  final Function(SuspiciousInterval interval) onSelectInterval;

  const TimelineIntervalsWidget({
    super.key,
    required this.totalDuration,
    required this.intervals,
    required this.selectedIntervalIndex,
    required this.onSelectInterval,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);
    final validDuration = totalDuration > 0 ? totalDuration : 10.0;

    return ForensicCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.timeline,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'SYNCHRONIZED TIMELINE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.8,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${intervals.length} Discrepanc${intervals.length == 1 ? "y" : "ies"} Detected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: intervals.isNotEmpty ? AppColors.warningOrange : AppColors.successGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Timeline Track
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;

              return Column(
                children: [
                  // Timeline Bar
                  Container(
                    height: 24,
                    width: trackWidth,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Safe track background
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Suspicious Intervals Highlighted
                        ...intervals.map((it) {
                          final double startFrac = (it.startTimeA / validDuration).clamp(0.0, 1.0);
                          final double endFrac = (it.endTimeA / validDuration).clamp(0.0, 1.0);
                          final double widthFrac = (endFrac - startFrac).clamp(0.03, 1.0);

                          final double leftPx = startFrac * trackWidth;
                          final double widthPx = (widthFrac * trackWidth).clamp(12.0, trackWidth);

                          final isSelected = it.intervalIndex == selectedIntervalIndex;
                          final Color color = it.severity == 'SIGNIFICANT'
                              ? AppColors.errorRed
                              : (it.severity == 'MODERATE' ? AppColors.warningOrange : Colors.amber);

                          return Positioned(
                            left: leftPx,
                            top: 0,
                            bottom: 0,
                            width: widthPx,
                            child: InkWell(
                              onTap: () => onSelectInterval(it),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? color : color.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: isSelected ? 1.5 : 0.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  it.intervalId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Timeline Scale Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('00:00.00', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                      Text('${(validDuration / 2).toStringAsFixed(1)}s', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                      Text('${validDuration.toStringAsFixed(1)}s', style: TextStyle(fontSize: 10, color: secondaryTextColor)),
                    ],
                  ),
                ],
              );
            },
          ),

          if (intervals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: intervals.map((it) {
                final isSelected = it.intervalIndex == selectedIntervalIndex;
                final Color color = it.severity == 'SIGNIFICANT'
                    ? AppColors.errorRed
                    : (it.severity == 'MODERATE' ? AppColors.warningOrange : Colors.amber);

                return ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: color,
                    radius: 5,
                  ),
                  label: Text(
                    '${it.intervalId} (${it.startTimeA.toStringAsFixed(1)}s - ${it.endTimeA.toStringAsFixed(1)}s)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: isSelected ? color.withValues(alpha: 0.2) : null,
                  side: BorderSide(
                    color: isSelected ? color : (isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1)),
                  ),
                  onPressed: () => onSelectInterval(it),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
