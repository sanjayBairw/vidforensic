import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/anomaly.dart';

class ForensicTimelineWidget extends StatelessWidget {
  final double duration;
  final List<Anomaly> anomalies;
  final Function(Anomaly)? onAnomalySelected;

  const ForensicTimelineWidget({
    super.key,
    required this.duration,
    required this.anomalies,
    this.onAnomalySelected,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = duration > 0 ? duration : 1.0;

    // Group anomalies by time proximity (within 2% of total duration)
    final double proximityThreshold = effectiveDuration * 0.02;
    final List<List<Anomaly>> groupedAnomalies = [];

    final sortedAnomalies = List<Anomaly>.from(anomalies)
      ..sort((a, b) => a.timestampStart.compareTo(b.timestampStart));

    for (final anomaly in sortedAnomalies) {
      if (groupedAnomalies.isEmpty) {
        groupedAnomalies.add([anomaly]);
      } else {
        final lastGroup = groupedAnomalies.last;
        final avgTime = lastGroup.map((e) => e.timestampStart).reduce((a, b) => a + b) / lastGroup.length;
        if ((anomaly.timestampStart - avgTime).abs() <= proximityThreshold) {
          lastGroup.add(anomaly);
        } else {
          groupedAnomalies.add([anomaly]);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FORENSIC TIMELINE MAP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            Text(
              '${anomalies.length} Event Marker(s)',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double trackWidth = constraints.maxWidth - 32;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Timeline Track Bar
                  Positioned(
                    left: 16,
                    right: 16,
                    height: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Markers
                  if (groupedAnomalies.isEmpty)
                    const Positioned.fill(
                      child: Center(
                        child: Text(
                          'No timeline events detected (Clean Stream)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...groupedAnomalies.map((group) {
                      final first = group.first;
                      final double avgTime = group.map((e) => e.timestampStart).reduce((a, b) => a + b) / group.length;
                      final double ratio = (avgTime / effectiveDuration).clamp(0.0, 1.0);
                      final double leftPos = 16 + (ratio * trackWidth) - 14;

                      final Color color = _getMarkerColor(first.type);
                      final IconData icon = _getMarkerIcon(first.type);

                      return Positioned(
                        left: leftPos,
                        child: GestureDetector(
                          onTap: () {
                            if (onAnomalySelected != null) {
                              onAnomalySelected!(first);
                            }
                          },
                          child: Tooltip(
                            message: group.length > 1
                                ? '${group.length} Anomalies around ${avgTime.toStringAsFixed(2)}s'
                                : '${first.anomalyType} at ${first.timestampStart.toStringAsFixed(2)}s',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 14, color: Colors.white),
                                  if (group.length > 1) ...[
                                    const SizedBox(width: 2),
                                    Text(
                                      '${group.length}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0.00s', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
            Text('${effectiveDuration.toStringAsFixed(2)}s', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Color _getMarkerColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('AI_CONTENT')) return Colors.indigo;
    if (t.contains('VISUAL_DISCONTINUITY')) return Colors.deepOrange;
    if (t.contains('VISUAL_ANOMALY')) return AppColors.statusError;
    if (t.contains('MODIFICATION')) return Colors.purple;
    if (t.contains('FREEZE')) return AppColors.primaryAccent;
    if (t.contains('DUPLICATE')) return Colors.lightBlue;
    if (t.contains('SCENE')) return Colors.teal;
    if (t.contains('PTS_GAP')) return Colors.orange;
    return AppColors.statusWarning;
  }

  IconData _getMarkerIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('AI_CONTENT')) return Icons.psychology;
    if (t.contains('VISUAL_DISCONTINUITY')) return Icons.broken_image;
    if (t.contains('VISUAL_ANOMALY')) return Icons.auto_awesome_motion;
    if (t.contains('MODIFICATION')) return Icons.edit_note;
    if (t.contains('FREEZE')) return Icons.ac_unit;
    if (t.contains('DUPLICATE')) return Icons.copy;
    if (t.contains('SCENE')) return Icons.movie_filter;
    if (t.contains('PTS_GAP')) return Icons.find_replace;
    return Icons.warning_amber;
  }
}
