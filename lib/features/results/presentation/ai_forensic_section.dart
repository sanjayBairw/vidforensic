import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confidence_badge.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../models/ai_forensic_result.dart';

class AiForensicSection extends StatelessWidget {
  final AiForensicResult? aiResult;

  const AiForensicSection({
    super.key,
    required this.aiResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (aiResult == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: ForensicCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.psychology_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No AI forensic assessment data recorded.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final res = aiResult!;
    final String cls = res.classification.toUpperCase();

    final bool isAi = (cls == 'LIKELY_AI_GENERATED');
    final bool isInconclusive = (cls == 'INCONCLUSIVE');

    final String statusTitle = isAi
        ? '🔴 LIKELY AI-GENERATED'
        : (isInconclusive ? '🟠 INCONCLUSIVE' : '🟢 LIKELY REAL / NO AI SIGNAL');

    final String statusSubtitle = isAi
        ? 'Multiple independent indicators are consistent with AI-generated video.'
        : (isInconclusive
            ? 'Available evidence is insufficient for reliable classification. Manual forensic review is recommended.'
            : 'No sufficient evidence of AI-generated content was detected.');

    final Color statusColor = isAi
        ? AppColors.statusError
        : (isInconclusive ? Colors.orange : AppColors.statusSuccess);

    final Color statusBgColor = statusColor.withValues(alpha: 0.12);
    final int confPercent = (res.confidenceScore * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MANDATORY DISCLAIMER BANNER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Automated forensic classification evaluates statistical visual & temporal patterns. It is not ground-truth proof of origin. Always review original provenance when available.',
                    style: TextStyle(fontSize: 12, color: Colors.amber[200], height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. PRIMARY AI CONTENT ANALYSIS CARD
          ForensicCard(
            borderColor: statusColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AI CONTENT ANALYSIS',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ConfidenceBadge(confidence: res.evidenceQuality),
                  ],
                ),
                const SizedBox(height: 14),

                // Primary Status Card Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAi
                            ? Icons.memory
                            : (isInconclusive ? Icons.help_outline : Icons.verified_outlined),
                        color: statusColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confidence: $confPercent%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              res.summary.isNotEmpty ? res.summary : statusSubtitle,
                              style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Provider & Risk Metadata Table
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow('Analysis Provider', res.modelProvider),
                      const Divider(height: 12),
                      _buildMetaRow('Evidence Quality', res.evidenceQuality),
                      const Divider(height: 12),
                      _buildMetaRow('Natural Artifact Risk', res.naturalArtifactRisk),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. KEY INDICATORS LIST (IF PRESENT)
          if (res.indicators.isNotEmpty) ...[
            Text(
              'Key Indicators Evaluated',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...res.indicators.map(
              (ind) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ind,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
