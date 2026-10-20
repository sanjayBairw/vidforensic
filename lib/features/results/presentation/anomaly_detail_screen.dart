import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confidence_badge.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../models/anomaly.dart';

class AnomalyDetailScreen extends StatelessWidget {
  final Anomaly anomaly;

  const AnomalyDetailScreen({
    super.key,
    required this.anomaly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: Text(anomaly.anomalyType),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SUMMARY CARD
            ForensicCard(
              borderColor: _getHeaderBorderColor(anomaly.type),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getHeaderBorderColor(anomaly.type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          anomaly.detector.toUpperCase(),
                          style: TextStyle(
                            color: _getHeaderBorderColor(anomaly.type),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      ConfidenceBadge(confidence: anomaly.confidence),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    anomaly.anomalyType,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    anomaly.evidence.isNotEmpty ? anomaly.evidence : 'Automated detector flagged anomaly candidate in frame sequence.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. REQUIREMENT 6: AI EVIDENCE BANNER & DISCLAIMER
            if (anomaly.isAiCandidate) ...[
              ForensicCard(
                borderColor: AppColors.statusError,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: AppColors.statusError, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'FORENSIC REVIEW REQUIRED',
                            style: TextStyle(
                              color: AppColors.statusError,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusError.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI Content Candidate Indicator',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.statusError),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This entry represents a statistical/spectral candidate indicator derived from FFT grid artifacts, PRNU noise residual analysis, and temporal warp flickering. '
                            'High-compression transcoding or camera sensor noise can produce similar anomalies. Expert manual forensic review and provenance verification are required. '
                            'This is an automated candidate flag, NOT absolute proof of AI generation.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (anomaly.isVisualAnomaly) ...[
              ForensicCard(
                borderColor: AppColors.statusWarning,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.statusWarning, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Visual Anomaly Candidate (Non-Fatal)',
                            style: TextStyle(
                              color: AppColors.statusWarning,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Frame decoded cleanly. High-noise visual characteristics or localized distortions detected. This does not indicate container bitstream decoding corruption (CORRUPTED_FRAME).',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. TEMPORAL & DETECTOR METRICS TABLE
            Text(
              'DETECTOR & TEMPORAL METRICS',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 10),

            ForensicCard(
              child: Column(
                children: [
                  _buildMetricRow('Detector Module:', anomaly.detector, isDark, secondaryTextColor),
                  _buildMetricRow('Finding Type:', anomaly.anomalyType, isDark, secondaryTextColor),
                  _buildMetricRow('Frame Range:', '${anomaly.frameStart} – ${anomaly.frameEnd}', isDark, secondaryTextColor),
                  _buildMetricRow('Timestamp Start:', '${anomaly.timestampStart.toStringAsFixed(3)} s', isDark, secondaryTextColor),
                  _buildMetricRow('Timestamp End:', '${anomaly.timestampEnd.toStringAsFixed(3)} s', isDark, secondaryTextColor),
                  _buildMetricRow('Duration:', '${anomaly.duration.toStringAsFixed(3)} s', isDark, secondaryTextColor),
                  _buildMetricRow('Detector Score:', anomaly.score.toStringAsFixed(4), isDark, secondaryTextColor),
                  _buildMetricRow('Confidence Level:', anomaly.confidence.toUpperCase(), isDark, secondaryTextColor),

                  // REQUIREMENT 7: MODIFICATION EVIDENCE DETAILS
                  if (anomaly.isModification) ...[
                    const Divider(height: 18),
                    _buildMetricRow(
                      'Entry Boundary:',
                      'Frame ${anomaly.frameBefore ?? (anomaly.frameStart > 0 ? anomaly.frameStart - 1 : 0)} → ${anomaly.frameStart}',
                      isDark,
                      secondaryTextColor,
                    ),
                    _buildMetricRow(
                      'Exit Boundary:',
                      'Frame ${anomaly.frameEnd} → ${anomaly.frameAfter ?? anomaly.frameEnd + 1}',
                      isDark,
                      secondaryTextColor,
                    ),
                    if (anomaly.regionDifference != null)
                      _buildMetricRow(
                        'Changed-Pixel Ratio:',
                        '${(anomaly.regionDifference! * 100).toStringAsFixed(2)}%',
                        isDark,
                        secondaryTextColor,
                      ),
                  ],

                  // REQUIREMENT 8: MISSING FRAME vs VISUAL DISCONTINUITY
                  if (anomaly.isPtsGap || anomaly.isVisualDiscontinuity) ...[
                    const Divider(height: 18),
                    _buildMetricRow(
                      'Timestamp Category:',
                      anomaly.isPtsGap ? 'PTS_GAP (Container Gap)' : 'VISUAL_DISCONTINUITY (Optical Flow Jump)',
                      isDark,
                      secondaryTextColor,
                    ),
                    _buildMetricRow(
                      'Container Timestamp Status:',
                      anomaly.isPtsGap ? 'Abnormal PTS Gap' : 'Normal Container Timestamps (No PTS Gap)',
                      isDark,
                      secondaryTextColor,
                    ),
                    _buildMetricRow(
                      'Estimated Missing Frames:',
                      anomaly.isVisualDiscontinuity ? '0 (Visual Jump Only)' : '${anomaly.estimatedMissing}',
                      isDark,
                      secondaryTextColor,
                    ),
                    if (anomaly.expectedInterval != null)
                      _buildMetricRow('Expected Interval:', '${anomaly.expectedInterval!.toStringAsFixed(4)} s', isDark, secondaryTextColor),
                    if (anomaly.actualInterval != null)
                      _buildMetricRow('Actual Interval:', '${anomaly.actualInterval!.toStringAsFixed(4)} s', isDark, secondaryTextColor),
                    if (anomaly.gapRatio != null)
                      _buildMetricRow('Gap Ratio:', '${anomaly.gapRatio!.toStringAsFixed(2)} x', isDark, secondaryTextColor),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. REQUIREMENT 6 & 7: EVIDENCE FRAME SNAPSHOTS (BEFORE, START, END, AFTER)
            _buildEvidenceSnapshotsSection(context, anomaly),

            const SizedBox(height: 20),

            // 5. FORENSIC SIGNALS CHIPS
            if (anomaly.signals.isNotEmpty) ...[
              Text(
                'DETECTOR SIGNALS EVALUATED',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              ForensicCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: anomaly.signals.entries.map((entry) {
                    return Chip(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      avatar: Icon(Icons.analytics, size: 14, color: theme.colorScheme.primary),
                      label: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 6. REQUIREMENT 7: DIFFERENCE REGIONS LIST
            if (anomaly.regions.isNotEmpty) ...[
              Text(
                'SUSPICIOUS DIFFERENCE REGIONS',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              ForensicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: anomaly.regions.map((reg) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outline_blank, size: 14, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'Region Box: $reg',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSnapshotsSection(BuildContext context, Anomaly anomaly) {
    final Map<String, String> imgs = anomaly.images;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    final Map<String, String> displayImages = {};
    if (imgs.isNotEmpty) {
      displayImages.addAll(imgs);
    } else {
      // Standard 4-frame labels required for evidence display
      displayImages['BEFORE'] = '';
      displayImages['DETECTED START'] = '';
      displayImages['DETECTED END'] = '';
      displayImages['AFTER'] = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EVIDENCE FRAME SNAPSHOTS',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: secondaryTextColor,
              ),
            ),
            Text(
              'Keyframes: BEFORE → START → END → AFTER',
              style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ForensicCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: displayImages.entries.map((entry) {
                final String label = entry.key.toUpperCase();
                final String url = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getLabelColor(label).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getLabelColor(label).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: _getLabelColor(label),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 130,
                        height: 85,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: url.isNotEmpty
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildPlaceholderSnapshot(label, isDark, secondaryTextColor),
                                )
                              : _buildPlaceholderSnapshot(label, isDark, secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderSnapshot(String label, bool isDark, Color secondaryColor) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 24, color: secondaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLabelColor(String label) {
    if (label.contains('BEFORE')) return Colors.blue;
    if (label.contains('START')) return AppColors.statusError;
    if (label.contains('END')) return Colors.orange;
    if (label.contains('AFTER')) return Colors.green;
    return const Color(0xFF2563EB);
  }

  Color _getHeaderBorderColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('AI_CONTENT')) return Colors.indigo;
    if (t.contains('MODIFICATION')) return Colors.purple;
    if (t.contains('VISUAL_DISCONTINUITY')) return Colors.deepOrange;
    if (t.contains('VISUAL_ANOMALY')) return AppColors.statusError;
    if (t.contains('PTS_GAP')) return Colors.orange;
    return const Color(0xFF2563EB);
  }

  Widget _buildMetricRow(String label, String value, bool isDark, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
