import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/network/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';
import '../../results/providers/results_provider.dart';
import '../../results/models/forensic_results.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ReportScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isOpening = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  String? _downloadedPath;
  String? _errorMessage;

  Future<String?> _fetchOrGetPdfPath() async {
    if (_downloadedPath != null && File(_downloadedPath!).existsSync()) {
      return _downloadedPath;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}${Platform.pathSeparator}video_forensic_report_${widget.jobId}.pdf';

      final apiClient = ref.read(apiClientProvider);
      await apiClient.downloadReport(widget.jobId, savePath);

      if (File(savePath).existsSync() && File(savePath).lengthSync() > 0) {
        setState(() {
          _downloadedPath = savePath;
        });
        return savePath;
      } else {
        throw Exception('Downloaded report file is empty or missing.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleOpenPdf() async {
    setState(() {
      _isOpening = true;
      _errorMessage = null;
    });

    try {
      final path = await _fetchOrGetPdfPath();
      if (path == null) throw Exception('Report unavailable.');

      final openResult = await OpenFilex.open(path);
      if (openResult.type != ResultType.done) {
        setState(() {
          _errorMessage = 'Report fetched, but failed to open: ${openResult.message}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to open PDF report: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      setState(() {
        _isOpening = false;
      });
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = await getExternalStorageDirectory();
      }
      targetDir ??= await getApplicationDocumentsDirectory();

      final savePath = '${targetDir.path}${Platform.pathSeparator}video_forensic_report_${widget.jobId}.pdf';

      final apiClient = ref.read(apiClientProvider);
      await apiClient.downloadReport(widget.jobId, savePath);

      setState(() {
        _downloadedPath = savePath;
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download complete: $savePath',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.statusSuccess,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Storage/Download Error: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _handleSharePdf() async {
    setState(() {
      _isSharing = true;
      _errorMessage = null;
    });

    try {
      final path = await _fetchOrGetPdfPath();
      if (path == null) throw Exception('Report unavailable.');

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(path)],
        text: 'VidForensic PDF Audit Report - Job ID: ${widget.jobId}',
        subject: 'VidForensic Report ${widget.jobId}',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to share report: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultsState = ref.watch(resultsProvider);
    final ForensicResults? res = resultsState.results;
    final ForensicSummary? summary = res?.summary;

    final String videoName = res?.videoName ?? 'Analyzed Video Sequence';
    final String statusStr = (res?.status ?? 'COMPLETED').toUpperCase();
    final int totalAnomalies = summary?.totalAnomalies ?? res?.anomalies.length ?? 0;
    final int aiCount = summary?.aiContentCandidates ?? 0;
    final int modCount = summary?.modificationCandidates ?? 0;
    final int missingCount = summary?.missingFrames ?? 0;

    // Determine Verdict Title & Colors
    Color verdictBgColor;
    Color verdictBorderColor;
    Color verdictTextColor;
    String verdictTitle;

    if (aiCount > 0) {
      verdictBgColor = AppColors.statusError.withValues(alpha: 0.1);
      verdictBorderColor = AppColors.statusError;
      verdictTextColor = AppColors.statusError;
      verdictTitle = 'AI CONTENT CANDIDATE / FORENSIC REVIEW REQUIRED';
    } else if (totalAnomalies > 0) {
      verdictBgColor = AppColors.statusWarning.withValues(alpha: 0.1);
      verdictBorderColor = AppColors.statusWarning;
      verdictTextColor = AppColors.statusWarning;
      verdictTitle = 'ANOMALIES DETECTED / FORENSIC REVIEW REQUIRED';
    } else {
      verdictBgColor = AppColors.statusSuccess.withValues(alpha: 0.1);
      verdictBorderColor = AppColors.statusSuccess;
      verdictTextColor = AppColors.statusSuccess;
      verdictTitle = 'NO FORENSIC ANOMALIES DETECTED';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          ForensicCard(
            padding: const EdgeInsets.all(24),
            borderColor: AppColors.primaryAccent.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon + Heading
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Formal PDF Forensic Audit Report',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Video: $videoName',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SelectableText(
                  'Job ID: ${widget.jobId}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Final Forensic Result Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: verdictBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: verdictBorderColor, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        verdictTitle,
                        style: TextStyle(
                          color: verdictTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Status: $statusStr  •  Report State: Ready',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Key Forensic Metrics Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildMetricItem('Total Anomalies', '$totalAnomalies', AppColors.statusWarning)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMetricItem('AI Candidates', '$aiCount', Colors.indigo)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildMetricItem('Modifications', '$modCount', Colors.purple)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMetricItem('Missing Frames', '$missingCount', Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'The backend PDF engine synthesizes multi-detector findings, FFT spectral grids, temporal frame changes, container timestamps, and SHA-256 hashes into a formal multi-page forensic audit document.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),

                const SizedBox(height: 20),

                if (_downloadedPath != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Local Copy: $_downloadedPath',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusError.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.statusError, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.statusError),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                AppButton(
                  label: 'OPEN PDF REPORT',
                  icon: Icons.picture_as_pdf,
                  isLoading: _isOpening,
                  onPressed: _handleOpenPdf,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download, size: 18),
                        label: Text(_isDownloading ? 'Downloading...' : 'DOWNLOAD PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primaryAccent),
                        ),
                        onPressed: _isDownloading ? null : _handleDownloadPdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.share, size: 18),
                        label: Text(_isSharing ? 'Preparing...' : 'SHARE PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primaryAccent),
                        ),
                        onPressed: _isSharing ? null : _handleSharePdf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
