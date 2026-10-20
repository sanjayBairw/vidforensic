import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/api_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/forensic_card.dart';
import '../providers/comparison_provider.dart';
import 'widgets/video_selection_card.dart';
import 'widgets/synchronized_player_widget.dart';
import 'widgets/timeline_intervals_widget.dart';
import 'widgets/comparison_summary_card.dart';
import 'widgets/metadata_table_widget.dart';
import 'widgets/evidence_intervals_card.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  bool _isDownloadingReport = false;
  bool _showAdvancedSettings = false;

  Future<void> _handleDownloadReport(String comparisonId) async {
    setState(() => _isDownloadingReport = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/forensic_comparison_${comparisonId.substring(0, 8)}.pdf';

      await apiClient.downloadComparisonReport(comparisonId, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded: $savePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                OpenFilex.open(savePath);
              },
            ),
          ),
        );
        // Attempt opening the report automatically
        await OpenFilex.open(savePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingReport = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comparisonProvider);
    final notifier = ref.read(comparisonProvider.notifier);
    final theme = Theme.of(context);
    final apiClient = ref.read(apiClientProvider);

    final evidenceBaseUrl = state.comparisonId != null
        ? apiClient.getEvidenceUrl(state.comparisonId!, '').replaceAll(RegExp(r'/$'), '')
        : null;

    final isAnalyzing = state.status == 'queued' || state.status == 'processing';
    final isCompleted = state.status == 'completed' && state.results != null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare, color: AppColors.primaryAccent, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Video Comparison',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (state.fileA != null || state.fileB != null || state.results != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Comparison',
              onPressed: () {
                notifier.reset();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Banner
            ForensicCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.difference, color: AppColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DUAL-VIDEO DIFFERENTIAL FORENSICS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload Reference (Original) and Suspected videos to detect splices, excised frames, localized modifications, and difference heatmaps.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Video Upload Cards (Side by side on wide screens, stacked on narrow screens)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final cardA = VideoSelectionCard(
                  title: 'Video A — Reference Video',
                  subtitle: 'Original / authentic ground truth video',
                  accentColor: AppColors.secondaryCyan,
                  file: state.fileA,
                  filename: state.nameA,
                  onPick: notifier.pickVideoA,
                  onRemove: notifier.clearVideoA,
                );

                final cardB = VideoSelectionCard(
                  title: 'Video B — Suspected Video',
                  subtitle: 'Comparison / suspect modified video',
                  accentColor: AppColors.warningOrange,
                  file: state.fileB,
                  filename: state.nameB,
                  onPick: notifier.pickVideoB,
                  onRemove: notifier.clearVideoB,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cardA),
                      const SizedBox(width: 14),
                      Expanded(child: cardB),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      cardA,
                      const SizedBox(height: 14),
                      cardB,
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 14),

            // Alignment and Sampling Settings (Collapsible)
            ForensicCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() => _showAdvancedSettings = !_showAdvancedSettings);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, size: 18, color: AppColors.primaryAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Alignment & Sampling Parameters',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Offset: ${state.timeOffset >= 0 ? "+" : ""}${state.timeOffset.toStringAsFixed(1)}s  •  Sample: ${state.sampleInterval}s',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showAdvancedSettings) ...[
                    const Divider(height: 20),
                    // Time Offset Slider (Responsive stacked format)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Time Offset (Alignment):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.timeOffset >= 0 ? "+" : ""}${state.timeOffset.toStringAsFixed(2)}s',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: state.timeOffset,
                          min: -5.0,
                          max: 5.0,
                          divisions: 100,
                          label: '${state.timeOffset.toStringAsFixed(2)}s',
                          onChanged: isAnalyzing ? null : notifier.setTimeOffset,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Sample Interval Slider (Responsive stacked format)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Sample Interval (Granularity):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.sampleInterval.toStringAsFixed(1)}s',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: state.sampleInterval,
                          min: 0.2,
                          max: 2.0,
                          divisions: 18,
                          label: '${state.sampleInterval.toStringAsFixed(1)}s',
                          onChanged: isAnalyzing ? null : notifier.setSampleInterval,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Start Comparison CTA Button (when not analyzing and not already completed)
            if (!isAnalyzing && !isCompleted) ...[
              AppButton(
                label: 'Start Video Comparison',
                icon: Icons.compare,
                onPressed: (state.fileA != null && state.fileB != null)
                    ? () {
                        notifier.startComparison();
                      }
                    : null,
              ),
            ],

            // Analysis Progress Card
            if (isAnalyzing) ...[
              ForensicCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppColors.primaryAccent.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.stage ?? 'Analyzing Videos...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Text(
                          '${(state.progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: state.progress > 0.0 ? state.progress : null,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state.message ?? 'Synchronizing video streams and extracting differential frame metrics...',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error Message Banner
            if (state.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // =================================================================
            // FORENSIC COMPARISON RESULTS DASHBOARD
            // =================================================================
            if (isCompleted && state.results != null) ...[
              const SizedBox(height: 10),

              // 1. Comparison Summary Card
              ComparisonSummaryCard(
                summary: state.results!.summary,
                isDownloadingReport: _isDownloadingReport,
                onDownloadReport: () => _handleDownloadReport(state.comparisonId!),
              ),
              const SizedBox(height: 16),

              // 2. Synchronized Video Player & Frame Viewer
              if (state.fileA != null && state.fileB != null) ...[
                SynchronizedPlayerWidget(
                  fileA: state.fileA!,
                  fileB: state.fileB!,
                  timeOffset: state.results!.timeOffset,
                  suspiciousIntervals: state.results!.suspiciousIntervals,
                  evidenceBaseUrl: evidenceBaseUrl,
                  activeIntervalIndex: state.selectedIntervalIndex,
                  onSeek: (secs) {
                    // Seek synchronized
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 3. Synchronized Timeline with Anomaly Intervals
              TimelineIntervalsWidget(
                totalDuration: state.results!.summary.overlapDuration,
                intervals: state.results!.suspiciousIntervals,
                selectedIntervalIndex: state.selectedIntervalIndex,
                onSelectInterval: (interval) {
                  notifier.selectInterval(interval.intervalIndex);
                },
              ),
              const SizedBox(height: 16),

              // 4. Metadata Audit & Comparison Table
              MetadataTableWidget(
                videoA: state.results!.videoA,
                videoB: state.results!.videoB,
                metadataComparison: state.results!.metadataComparison,
              ),
              const SizedBox(height: 16),

              // 5. Evidence Plates & Difference Heatmaps Gallery
              EvidenceIntervalsCard(
                intervals: state.results!.suspiciousIntervals,
                evidenceBaseUrl: evidenceBaseUrl,
                selectedIntervalIndex: state.selectedIntervalIndex,
                onSelectInterval: (interval) {
                  notifier.selectInterval(interval.intervalIndex);
                },
              ),
              const SizedBox(height: 16),

              // 6. Forensic Limitations & Legal Notice
              ForensicCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'FORENSIC LIMITATIONS & LEGAL DISCLAIMER',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...state.results!.limitations.map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $l',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
