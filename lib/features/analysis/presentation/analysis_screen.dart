import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../../shared/widgets/status_indicator.dart';
import '../providers/analysis_provider.dart';
import '../../results/presentation/results_dashboard_screen.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  final String jobId;

  const AnalysisScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisProvider.notifier).startAnalysis(widget.jobId);
    });
  }

  final List<String> _stages = const [
    'Frame Analysis',
    'Freeze Detection',
    'Duplicate Detection',
    'Missing Frame Detection',
    'Corrupted Frame Detection',
    'Modification Detection',
    'Scene Detection',
    'Copy-Move Forgery Detection',
    'Splicing Detection',
    'AI Forensic Detection',
    'Evidence Fusion',
    'Report Generation',
  ];

  int _parseActiveStageIndex(String? stageStr, double progress) {
    if (stageStr != null && stageStr.isNotEmpty) {
      final match = RegExp(r'\[(\d+)/12\]').firstMatch(stageStr);
      if (match != null) {
        final parsed = int.tryParse(match.group(1) ?? '');
        if (parsed != null && parsed >= 1 && parsed <= _stages.length) {
          return parsed - 1;
        }
      }
      final lower = stageStr.toLowerCase();
      for (int i = 0; i < _stages.length; i++) {
        if (lower.contains(_stages[i].toLowerCase())) {
          return i;
        }
      }
    }
    return (progress * _stages.length).floor().clamp(0, _stages.length - 1);
  }

  StageStatus _getStageStatus(int index, String overallStatus, double progress, String? currentStage) {
    if (overallStatus == 'completed') {
      return StageStatus.completed;
    }
    final activeIdx = _parseActiveStageIndex(currentStage, progress);
    if (overallStatus == 'failed') {
      if (index < activeIdx) return StageStatus.completed;
      if (index == activeIdx) return StageStatus.failed;
      return StageStatus.waiting;
    }

    if (index < activeIdx) {
      return StageStatus.completed;
    } else if (index == activeIdx) {
      return StageStatus.processing;
    } else {
      return StageStatus.waiting;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final theme = Theme.of(context);

    ref.listen<AnalysisState>(analysisProvider, (previous, next) {
      if (next.status == 'completed' && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsDashboardScreen(jobId: widget.jobId),
          ),
        );
      }
    });

    final percentStr = (analysisState.progress.clamp(0.0, 1.0) * 100).toInt();
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forensic Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header Card
            ForensicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ANALYSIS IN PROGRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '$percentStr%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Job ID: ${widget.jobId}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: analysisState.progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                  if (analysisState.currentStage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Stage: ${analysisState.currentStage}',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'FORENSIC PIPELINE STAGES',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Pipeline Stages List Card
            ForensicCard(
              child: Column(
                children: List.generate(_stages.length, (index) {
                  final stageName = _stages[index];
                  final status = _getStageStatus(index, analysisState.status, analysisState.progress, analysisState.currentStage);
                  return StatusIndicator(
                    title: stageName,
                    status: status,
                  );
                }),
              ),
            ),

            if (analysisState.status == 'failed') ...[
              const SizedBox(height: 20),
              ForensicCard(
                borderColor: AppColors.statusError,
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.statusError, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Analysis Failed',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusError, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysisState.error ?? 'An unknown error occurred during forensic execution.',
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Back to Home',
                            isSecondary: true,
                            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Retry Analysis',
                            icon: Icons.refresh,
                            onPressed: () {
                              ref.read(analysisProvider.notifier).startAnalysis(widget.jobId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
