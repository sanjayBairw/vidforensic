import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../../results/presentation/results_dashboard_screen.dart';
import '../../video_selection/presentation/video_selection_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyProvider);

    return Scaffold(

      appBar: AppBar(
        title: const Text('Analysis History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh History',
            onPressed: () {
              ref.read(historyProvider.notifier).refreshHistory();
            },
          ),
          if (historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All History',
              onPressed: () {
                _showClearAllDialog(context, ref);
              },
            ),
        ],
      ),
      body: historyList.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(historyProvider.notifier).refreshHistory();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];
                  return _buildHistoryCard(context, ref, item);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No forensic analyses yet.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a video to start your first analysis.',
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: AppButton(
                label: 'ANALYZE VIDEO',
                icon: Icons.video_call_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VideoSelectionScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, HistoryItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);
    final statusUpper = item.status.toUpperCase();
    final isCompleted = statusUpper == 'COMPLETED';
    final isProcessing = statusUpper == 'PROCESSING' || statusUpper == 'QUEUED' || statusUpper == 'UPLOADED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ForensicCard(
        onTap: () {
          if (isCompleted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsDashboardScreen(jobId: item.jobId),
              ),
            );
          } else if (statusUpper == 'FAILED') {
            _showErrorDialog(context, item);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Job ${item.jobId} is currently processing (${item.status}).'),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(statusUpper),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(statusUpper),
                    color: _getStatusColor(statusUpper),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.filename.isNotEmpty ? item.filename : item.jobId,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${item.jobId} • ${item.date}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: secondaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(statusUpper),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getStatusColor(statusUpper).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isProcessing) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.statusWarning),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        statusUpper,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(statusUpper),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: secondaryTextColor),
                  tooltip: 'Delete Job',
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, ref, item);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Overall Forensic Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getForensicBannerBg(item.overallForensicStatus, isDark),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    _getForensicBannerIcon(item.overallForensicStatus),
                    size: 14,
                    color: _getForensicBannerColor(item.overallForensicStatus, isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.overallForensicStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: _getForensicBannerColor(item.overallForensicStatus, isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Metrics Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem('Total Anomalies', '${item.anomalyCount}', isDark, secondaryTextColor),
                _buildMetricItem('AI Candidates', '${item.aiCandidates}', isDark, secondaryTextColor),
                _buildMetricItem('Modifications', '${item.modificationCandidates}', isDark, secondaryTextColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: secondaryColor),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.statusSuccess;
      case 'PROCESSING':
      case 'QUEUED':
      case 'UPLOADED':
        return AppColors.statusWarning;
      case 'FAILED':
        return AppColors.statusError;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    return _getStatusColor(status).withValues(alpha: 0.12);
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'PROCESSING':
      case 'QUEUED':
      case 'UPLOADED':
        return Icons.sync;
      case 'FAILED':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getForensicBannerColor(String overallStatus, bool isDark) {
    switch (overallStatus) {
      case 'AI CONTENT CANDIDATE':
        return isDark ? Colors.amber[400]! : Colors.amber[800]!;
      case 'FORENSIC REVIEW REQUIRED':
        return isDark ? Colors.cyan[400]! : Colors.cyan[800]!;
      case 'NO FORENSIC ANOMALIES':
        return AppColors.statusSuccess;
      case 'ANALYSIS FAILED':
        return AppColors.statusError;
      default:
        return isDark ? Colors.grey[400]! : const Color(0xFF64748B);
    }
  }

  Color _getForensicBannerBg(String overallStatus, bool isDark) {
    return _getForensicBannerColor(overallStatus, isDark).withValues(alpha: 0.12);
  }

  IconData _getForensicBannerIcon(String overallStatus) {
    switch (overallStatus) {
      case 'AI CONTENT CANDIDATE':
        return Icons.memory;
      case 'FORENSIC REVIEW REQUIRED':
        return Icons.warning_amber_rounded;
      case 'NO FORENSIC ANOMALIES':
        return Icons.verified;
      default:
        return Icons.info_outline;
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text(
          'Are you sure you want to delete analysis job "${item.jobId}" (${item.filename})?\n\nThis will remove all stored forensic results and reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(historyProvider.notifier).deleteJob(item.jobId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Job "${item.filename}" deleted successfully.'
                          : 'Failed to delete job.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'Are you sure you want to delete all persistent analysis history records and associated files?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(historyProvider.notifier).clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All history cleared.')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Job Failed'),
        content: Text(
          item.errorMessage ?? 'An unexpected error occurred during forensic analysis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
