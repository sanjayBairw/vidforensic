import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/forensic_card.dart';
import '../../models/comparison_models.dart';

class MetadataTableWidget extends StatelessWidget {
  final VideoMetadata videoA;
  final VideoMetadata videoB;
  final MetadataComparison metadataComparison;

  const MetadataTableWidget({
    super.key,
    required this.videoA,
    required this.videoB,
    required this.metadataComparison,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return ForensicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'METADATA AUDIT & DISCREPANCY ANALYSIS',
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
          const SizedBox(height: 12),

          // Side-by-side Table
          Table(
            border: TableBorder.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
              width: 0.5,
              borderRadius: BorderRadius.circular(4),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(2.0),
              3: FlexColumnWidth(1.2),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                ),
                children: [
                  _buildCell('Property', isHeader: true),
                  _buildCell('Video A (Reference)', isHeader: true, color: AppColors.secondaryCyan),
                  _buildCell('Video B (Suspected)', isHeader: true, color: AppColors.warningOrange),
                  _buildCell('Status', isHeader: true),
                ],
              ),
              // Filename
              TableRow(
                children: [
                  _buildCell('Filename'),
                  _buildCell(videoA.filename),
                  _buildCell(videoB.filename),
                  _buildStatusChip('Documented', AppColors.neutralConfidence),
                ],
              ),
              // Resolution
              TableRow(
                children: [
                  _buildCell('Resolution'),
                  _buildCell('${videoA.width}x${videoA.height} (${videoA.aspectRatio})'),
                  _buildCell('${videoB.width}x${videoB.height} (${videoB.aspectRatio})'),
                  _buildStatusChip(
                    metadataComparison.resolutionMatch ? 'MATCH' : 'DIFFERENT',
                    metadataComparison.resolutionMatch ? AppColors.successGreen : AppColors.warningOrange,
                  ),
                ],
              ),
              // Frame Rate
              TableRow(
                children: [
                  _buildCell('Frame Rate'),
                  _buildCell('${videoA.fps.toStringAsFixed(2)} FPS'),
                  _buildCell('${videoB.fps.toStringAsFixed(2)} FPS'),
                  _buildStatusChip(
                    metadataComparison.fpsMatch ? 'MATCH' : 'MISMATCH',
                    metadataComparison.fpsMatch ? AppColors.successGreen : AppColors.warningOrange,
                  ),
                ],
              ),
              // Duration
              TableRow(
                children: [
                  _buildCell('Duration'),
                  _buildCell('${videoA.duration.toStringAsFixed(2)}s'),
                  _buildCell('${videoB.duration.toStringAsFixed(2)}s'),
                  _buildStatusChip(
                    metadataComparison.durationMatch ? 'MATCH' : 'DELTA: ${metadataComparison.durationDelta.toStringAsFixed(2)}s',
                    metadataComparison.durationMatch ? AppColors.successGreen : AppColors.warningOrange,
                  ),
                ],
              ),
              // File Size
              TableRow(
                children: [
                  _buildCell('File Size'),
                  _buildCell(Formatters.formatFileSize(videoA.fileSize)),
                  _buildCell(Formatters.formatFileSize(videoB.fileSize)),
                  _buildStatusChip('${metadataComparison.sizeRatio}x', theme.colorScheme.primary),
                ],
              ),
              // Codec & Container
              TableRow(
                children: [
                  _buildCell('Container/Codec'),
                  _buildCell('${videoA.container.toUpperCase()} (${videoA.codec})'),
                  _buildCell('${videoB.container.toUpperCase()} (${videoB.codec})'),
                  _buildStatusChip(
                    videoA.container == videoB.container ? 'MATCH' : 'DIFFERENT',
                    videoA.container == videoB.container ? AppColors.successGreen : secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),

          // Discrepancies Callout
          if (metadataComparison.discrepancies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.warningOrange),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Observed Technical Discrepancies:',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...metadataComparison.discrepancies.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '• [${d.category}]: ${d.detail}',
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 10.5,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
