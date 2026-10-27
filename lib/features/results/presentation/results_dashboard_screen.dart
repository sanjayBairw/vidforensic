import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/forensic_card.dart';

import '../../history/models/history_item.dart';
import '../../history/providers/history_provider.dart';

import '../../report/presentation/report_screen.dart';

import '../models/anomaly.dart';
import '../models/forensic_results.dart';
import '../providers/results_provider.dart';

class ResultsDashboardScreen extends ConsumerStatefulWidget {
  final String jobId;

  const ResultsDashboardScreen({super.key, required this.jobId});

  @override
  ConsumerState<ResultsDashboardScreen> createState() =>
      _ResultsDashboardScreenState();
}

class _ResultsDashboardScreenState extends ConsumerState<ResultsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Prevent duplicate history entries.
  bool _historyAdded = false;

  // Expand/collapse state for each detector anomaly list.
  // Key = detector name string, Value = whether fully expanded.
  final Map<String, bool> _expandedDetectors = {};

  bool _isExpanded(String key) => _expandedDetectors[key] == true;

  void _toggleDetector(String key) {
    setState(() {
      _expandedDetectors[key] = !_isExpanded(key);
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // ============================================================
    // ALWAYS FETCH THE CURRENT JOB
    // ============================================================

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final currentState = ref.read(resultsProvider);
      if (currentState.jobId == widget.jobId &&
          (currentState.isLoading ||
              currentState.results != null ||
              currentState.error != null)) {
        if (currentState.results != null && !_historyAdded) {
          _historyAdded = true;
          final res = currentState.results!;
          ref.read(historyProvider.notifier).addItem(
                HistoryItem(
                  jobId: widget.jobId,
                  filename: res.videoName,
                  date: res.createdAt.isNotEmpty
                      ? res.createdAt
                      : DateTime.now().toIso8601String().split('T').first,
                  status: res.status,
                  anomalyCount:
                      res.summary?.totalAnomalies ?? res.anomalies.length,
                ),
              );
        }
        return;
      }

      debugPrint('');
      debugPrint('==============================================');
      debugPrint('DASHBOARD: FETCHING CURRENT JOB');
      debugPrint('JOB ID: ${widget.jobId}');
      debugPrint('==============================================');

      await ref.read(resultsProvider.notifier).fetchResults(widget.jobId);

      if (!mounted) return;

      final state = ref.read(resultsProvider);

      if (state.results != null && !_historyAdded) {
        _historyAdded = true;

        final res = state.results!;

        ref
            .read(historyProvider.notifier)
            .addItem(
              HistoryItem(
                jobId: widget.jobId,
                filename: res.videoName,
                date: res.createdAt.isNotEmpty
                    ? res.createdAt
                    : DateTime.now().toIso8601String().split('T').first,
                status: res.status,
                anomalyCount:
                    res.summary?.totalAnomalies ?? res.anomalies.length,
              ),
            );
      }
    });
  }

  // ================================================================
  // HANDLE JOB ID CHANGES
  // ================================================================

  @override
  void didUpdateWidget(covariant ResultsDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.jobId != widget.jobId) {
      _historyAdded = false;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        debugPrint('');
        debugPrint('==============================================');
        debugPrint('DASHBOARD JOB CHANGED');
        debugPrint('OLD JOB: ${oldWidget.jobId}');
        debugPrint('NEW JOB: ${widget.jobId}');
        debugPrint('==============================================');

        await ref.read(resultsProvider.notifier).fetchResults(widget.jobId);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final resultsState = ref.watch(resultsProvider);

    // ============================================================
    // SAFETY: Do not display another job's result.
    // ============================================================

    final bool isCurrentJob = resultsState.jobId == widget.jobId;

    final ForensicResults? currentResults = isCurrentJob
        ? resultsState.results
        : null;

    // ============================================================
    // PROCESSING / LOADING DIFFERENT JOB
    // ============================================================

    if (resultsState.isLoading || !isCurrentJob) {
      return Scaffold(
        appBar: AppBar(title: Text('Job: ${widget.jobId}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ForensicCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analyzing Video Sequence...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Job ID: ${widget.jobId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildStageStep('Uploading & Validating', isDone: true),
                  _buildStageStep(
                    'Processing Multi-Detector Pipeline',
                    isActive: true,
                  ),
                  _buildStageStep(
                    'Synthesizing Evidence & Generating PDF',
                    isPending: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // ERROR
    // ============================================================

    if (resultsState.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Job: ${widget.jobId}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ForensicCard(
              borderColor: AppColors.statusError,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.statusError,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Forensic Analysis Failed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.statusError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Job ID: ${widget.jobId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resultsState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Retry Analysis Fetch',
                    icon: Icons.refresh,
                    onPressed: () async {
                      await ref
                          .read(resultsProvider.notifier)
                          .fetchResults(widget.jobId);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // NO RESULT
    // ============================================================

    if (currentResults == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Forensic Results')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ForensicCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No forensic result available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Job ID: ${widget.jobId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'FETCH RESULT',
                    icon: Icons.refresh,
                    onPressed: () async {
                      await ref
                          .read(resultsProvider.notifier)
                          .fetchResults(widget.jobId);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // COMPLETED RESULTS
    // ============================================================

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forensic Results'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'PDF Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(context, currentResults),

          // IMPORTANT: PDF uses current widget.jobId.
          ReportScreen(jobId: widget.jobId),
        ],
      ),
    );
  }

  // ================================================================
  // STAGE STEP
  // ================================================================

  Widget _buildStageStep(
    String title, {
    bool isDone = false,
    bool isActive = false,
    bool isPending = false,
  }) {
    Color color = Colors.grey;
    IconData icon = Icons.circle_outlined;

    if (isDone) {
      color = AppColors.statusSuccess;
      icon = Icons.check_circle;
    } else if (isActive) {
      color = AppColors.primaryAccent;
      icon = Icons.sync;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF111827))
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : const Color(0xFF64748B)),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY TAB
  // ================================================================

  Widget _buildSummaryTab(BuildContext context, ForensicResults? res) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ai = res?.aiDetection;
    String rawClass = ai?.classification.trim().toUpperCase() ?? '';
    rawClass = _normalizeClassification(rawClass);

    if (rawClass.isEmpty) {
      rawClass = 'INCONCLUSIVE';
    }

    final summary = res?.summary;
    final int totalAnomalies =
        summary?.totalAnomalies ?? res?.anomalies.length ?? 0;

    final List<Anomaly> anomalies = res?.anomalies ?? [];

    // Filter detector anomaly lists
    final freezeAnomalies = anomalies
        .where((a) => a.type.toUpperCase().contains('FREEZE'))
        .toList();
    final dupAnomalies = anomalies
        .where((a) => a.type.toUpperCase().contains('DUPLICATE'))
        .toList();
    final missingAnomalies = anomalies
        .where((a) =>
            a.isPtsGap ||
            a.isVisualDiscontinuity ||
            a.type.toUpperCase().contains('MISSING'))
        .toList();
    final corruptedAnomalies = anomalies
        .where((a) =>
            a.isCorruptedFrame ||
            a.isVisualAnomaly ||
            a.type.toUpperCase().contains('CORRUPT'))
        .toList();
    final modAnomalies = anomalies
        .where((a) => a.isModification || a.type.toUpperCase().contains('MODIF'))
        .toList();
    final sceneAnomalies = anomalies
        .where((a) => a.type.toUpperCase().contains('SCENE'))
        .toList();
    final copyMoveAnomalies = anomalies
        .where((a) => a.isCopyMove || a.type.toUpperCase().contains('COPY_MOVE'))
        .toList();
    final spliceAnomalies = anomalies
        .where((a) => a.isSplice || a.type.toUpperCase().contains('SPLICE'))
        .toList();
    final objAnomalies = anomalies
        .where((a) => a.isObjectManipulation || a.type.toUpperCase().contains('OBJECT'))
        .toList();
    final compAnomalies = anomalies
        .where((a) => a.isCompressionAnomaly || a.type.toUpperCase().contains('COMPRESSION'))
        .toList();
    final metaAnomalies = anomalies
        .where((a) => a.isMetadataAnomaly || a.type.toUpperCase().contains('METADATA'))
        .toList();
    final audioAnomalies = anomalies
        .where((a) => a.isAudioSyncAnomaly || a.type.toUpperCase().contains('AUDIO') || a.type.toUpperCase().contains('DESYNC'))
        .toList();

    // Counts
    final int freezeCount = summary?.freezeFrames ?? freezeAnomalies.length;
    final int dupCount = summary?.duplicateFrames ?? dupAnomalies.length;
    final int missingCount = summary?.missingFrames ?? missingAnomalies.length;
    final int corruptedCount = summary?.corruptedFrames ?? corruptedAnomalies.length;
    final int modCount = summary?.modificationCandidates ?? modAnomalies.length;
    final int sceneCount = summary?.sceneChanges ?? sceneAnomalies.length;
    final int copyMoveCount = summary?.copyMoveCandidates ?? copyMoveAnomalies.length;
    final int spliceCount = summary?.spliceCandidates ?? spliceAnomalies.length;
    final int objCount = summary?.objectManipulationCandidates ?? objAnomalies.length;
    final int compCount = summary?.compressionAnomalies ?? compAnomalies.length;
    final int metaCount = summary?.metadataInconsistencies ?? metaAnomalies.length;
    final int audioCount = summary?.audioSyncAnomalies ?? audioAnomalies.length;

    // Availability checks
    final bool freezeAvailable = _isDetectorAvailable(res, 'freeze_results');
    final bool dupAvailable = _isDetectorAvailable(res, 'duplicate_results');
    final bool missingAvailable = _isDetectorAvailable(res, 'missing_results');
    final bool corruptedAvailable = _isDetectorAvailable(res, 'corrupted_results');
    final bool modAvailable = _isDetectorAvailable(res, 'modification_results');
    final bool sceneAvailable = _isDetectorAvailable(res, 'scene_results');
    final bool copyMoveAvailable = _isDetectorAvailable(res, 'copy_move_results');
    final bool spliceAvailable = _isDetectorAvailable(res, 'splicing_results');
    final bool objAvailable = _isDetectorAvailable(res, 'object_manipulation_results');
    final bool compAvailable = _isDetectorAvailable(res, 'compression_results');
    final bool metaAvailable = _isDetectorAvailable(res, 'metadata_results');
    final bool audioAvailable = _isDetectorAvailable(res, 'audio_sync_results');

    // ============================================================
    // DEBUG LOGGING
    // ============================================================

    debugPrint('');
    debugPrint('==============================================');
    debugPrint('DASHBOARD CURRENT JOB');
    debugPrint('REQUESTED JOB ID: ${widget.jobId}');
    debugPrint('PROVIDER JOB ID: ${ref.read(resultsProvider).jobId}');
    debugPrint('VIDEO: ${res?.videoName}');
    debugPrint('AI CLASS: $rawClass');
    debugPrint('AI CANDIDATES: ${ai?.candidateCount ?? 0}');
    debugPrint('TOTAL ANOMALIES: $totalAnomalies');
    debugPrint('MISSING: $missingCount (Avail: $missingAvailable)');
    debugPrint('FREEZE: $freezeCount (Avail: $freezeAvailable)');
    debugPrint('DUPLICATE: $dupCount (Avail: $dupAvailable)');
    debugPrint('CORRUPTED: $corruptedCount (Avail: $corruptedAvailable)');
    debugPrint('MODIFIED: $modCount (Avail: $modAvailable)');
    debugPrint('SCENE: $sceneCount (Avail: $sceneAvailable)');
    debugPrint('==============================================');
    debugPrint('');

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (rawClass == 'LIKELY_AI_GENERATED') {
      statusColor = AppColors.statusError;
      statusTitle = '🔴 AI GENERATED';
      statusIcon = Icons.memory;
    } else if (rawClass == 'INCONCLUSIVE') {
      statusColor = Colors.orange;
      statusTitle = '🟠 INCONCLUSIVE';
      statusIcon = Icons.help_outline;
    } else if (rawClass == 'LIKELY_REAL') {
      statusColor = AppColors.statusSuccess;
      statusTitle = '🟢 NO AI DETECTED';
      statusIcon = Icons.verified_outlined;
    } else {
      statusColor = Colors.orange;
      statusTitle = '🟠 INCONCLUSIVE';
      statusIcon = Icons.help_outline;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ======================================================
          // 1. FINAL AI CLASSIFICATION RESULT CARD
          // ======================================================
          ForensicCard(
            borderColor: statusColor.withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              child: Column(
                children: [
                  Icon(statusIcon, size: 52, color: statusColor),
                  const SizedBox(height: 14),
                  Text(
                    'FINAL RESULT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (ai != null && rawClass != 'INCONCLUSIVE') ...[
                    const SizedBox(height: 14),
                    Text(
                      'Confidence: ${(ai.confidenceScore * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Evidence: ${ai.evidenceQuality}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (ai.modelProvider.isNotEmpty &&
                        ai.modelProvider != 'unknown') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Provider: ${ai.modelProvider}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // 2. FORENSIC DETECTION RESULTS SECTION HEADER
          // ======================================================
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
            child: Text(
              'FORENSIC DETECTION RESULTS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),

          // ------------------------------------------------------
          // 1. FREEZE DETECTOR CARD
          // ------------------------------------------------------
          _buildFreezeDetectorCard(
            isAvailable: freezeAvailable,
            count: freezeCount,
            anomalies: freezeAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 2. DUPLICATE DETECTOR CARD
          // ------------------------------------------------------
          _buildDuplicateDetectorCard(
            isAvailable: dupAvailable,
            count: dupCount,
            anomalies: dupAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 3. MISSING DETECTOR CARD
          // ------------------------------------------------------
          _buildMissingDetectorCard(
            isAvailable: missingAvailable,
            count: missingCount,
            anomalies: missingAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 4. CORRUPTED DETECTOR CARD
          // ------------------------------------------------------
          _buildCorruptedDetectorCard(
            isAvailable: corruptedAvailable,
            count: corruptedCount,
            anomalies: corruptedAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 5. MODIFICATION DETECTOR CARD
          // ------------------------------------------------------
          _buildModificationDetectorCard(
            isAvailable: modAvailable,
            count: modCount,
            anomalies: modAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 6. SCENE DETECTOR CARD
          // ------------------------------------------------------
          _buildSceneDetectorCard(
            isAvailable: sceneAvailable,
            count: sceneCount,
            anomalies: sceneAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 7. COPY-MOVE FORGERY DETECTOR CARD
          // ------------------------------------------------------
          _buildCopyMoveDetectorCard(
            isAvailable: copyMoveAvailable,
            count: copyMoveCount,
            anomalies: copyMoveAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 8. SPLICING DETECTOR CARD
          // ------------------------------------------------------
          _buildSpliceDetectorCard(
            isAvailable: spliceAvailable,
            count: spliceCount,
            anomalies: spliceAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 9. OBJECT MANIPULATION & INPAINTING CARD
          // ------------------------------------------------------
          _buildObjectManipulationCard(
            isAvailable: objAvailable,
            count: objCount,
            anomalies: objAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 10. COMPRESSION & RE-ENCODING ANALYSIS CARD
          // ------------------------------------------------------
          _buildCompressionForensicsCard(
            isAvailable: compAvailable,
            count: compCount,
            anomalies: compAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 11. METADATA & CONTAINER TIMESTAMP CARD
          // ------------------------------------------------------
          _buildMetadataAuditCard(
            isAvailable: metaAvailable,
            count: metaCount,
            anomalies: metaAnomalies,
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // 12. AUDIO/VIDEO SYNCHRONIZATION CARD
          // ------------------------------------------------------
          _buildAudioSyncCard(
            isAvailable: audioAvailable,
            count: audioCount,
            anomalies: audioAnomalies,
          ),
          const SizedBox(height: 24),

          // ======================================================
          // 3. SUMMARY TOTAL & PDF REPORT BUTTON CARD
          // ======================================================
          ForensicCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Anomalies',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: totalAnomalies > 0
                              ? Colors.orange.withValues(alpha: 0.2)
                              : AppColors.statusSuccess.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: totalAnomalies > 0
                                ? Colors.orange.withValues(alpha: 0.6)
                                : AppColors.statusSuccess.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '$totalAnomalies',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: totalAnomalies > 0
                                ? Colors.orange
                                : AppColors.statusSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'VIEW PDF REPORT',
                    icon: Icons.picture_as_pdf,
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ================================================================
  // DETECTOR AVAILABILITY CHECKER
  // ================================================================

  bool _isDetectorAvailable(ForensicResults? res, String detectorKey) {
    if (res == null) return false;
    final raw = res.rawDetectors;
    if (raw.containsKey(detectorKey)) return true;
    if (raw.isNotEmpty) return false;
    // Fallback: If summary or evidence_results exists, detector was run in pipeline
    return res.summary != null;
  }

  // ================================================================
  // DETECTOR CARD BUILDERS
  // ================================================================

  // 1. FREEZE DETECTOR CARD
  Widget _buildFreezeDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('FREEZE DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO FREEZE DETECTED',
        subtext: 'No freeze frame event was detected.',
      );
    }

    const expandKey = 'freeze';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ForensicCard(
      borderColor: Colors.orange.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '⚠️ FREEZE FRAME DETECTED',
              color: Colors.orange,
              icon: Icons.pause_circle_outline,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Occurrences: $count freeze event(s) detected',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.orange[200] : Colors.orange[900]),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              final int frameCount = a.frameEnd >= a.frameStart
                  ? (a.frameEnd - a.frameStart + 1)
                  : (a.rawJson['frames'] as num?)?.toInt() ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Frame Range', '${a.frameStart} - ${a.frameEnd}'),
                    _buildDetailRow('Timestamp',
                        '${a.timestampStart.toStringAsFixed(2)}s - ${a.timestampEnd.toStringAsFixed(2)}s'),
                    if (frameCount > 0)
                      _buildDetailRow('Frozen Frames', '$frameCount'),
                    _buildDetailRow(
                        'Duration', '${a.duration.toStringAsFixed(2)}s'),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  // 2. DUPLICATE DETECTOR CARD
  Widget _buildDuplicateDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('DUPLICATE FRAME DETECTED');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO DUPLICATE FRAMES DETECTED',
        subtext: 'No duplicate frame ranges detected.',
      );
    }

    const expandKey = 'duplicate';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ForensicCard(
      borderColor: Colors.orange.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '⚠️ DUPLICATE FRAMES DETECTED',
              color: Colors.orange,
              icon: Icons.control_point_duplicate,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Occurrences: $count duplicate range(s) detected',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.orange[200] : Colors.orange[900]),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              final int frameCount = a.frameEnd >= a.frameStart
                  ? (a.frameEnd - a.frameStart + 1)
                  : 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Frame Range', '${a.frameStart} - ${a.frameEnd}'),
                    _buildDetailRow('Timestamp',
                        '${a.timestampStart.toStringAsFixed(2)}s - ${a.timestampEnd.toStringAsFixed(2)}s'),
                    _buildDetailRow('Duplicate Frames', '$frameCount'),
                    _buildDetailRow(
                        'Duration', '${a.duration.toStringAsFixed(2)}s'),
                    const Divider(color: Colors.white10, height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  // 3. MISSING DETECTOR CARD
  Widget _buildMissingDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('MISSING FRAME DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO MISSING FRAMES DETECTED',
        subtext: 'No PTS gaps or visual discontinuities detected.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = isDark ? Colors.orange[300]! : Colors.orange[800]!;
    const expandKey = 'missing';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: Colors.orange.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '⚠️ MISSING FRAMES DETECTED',
              color: warningColor,
              icon: Icons.movie_filter_outlined,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Missing Frames: $count',
              style: TextStyle(fontSize: 13, color: warningColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              final fBefore = a.frameBefore ?? a.frameStart;
              final fAfter = a.frameAfter ?? a.frameEnd;
              final tBefore = a.timestampBefore ?? a.timestampStart;
              final tAfter = a.timestampAfter ?? a.timestampEnd;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Frame Gap', '$fBefore → $fAfter'),
                    _buildDetailRow('Timestamp',
                        '${tBefore.toStringAsFixed(2)}s → ${tAfter.toStringAsFixed(2)}s'),
                    if (a.actualInterval != null)
                      _buildDetailRow(
                          'Actual Gap', '${a.actualInterval!.toStringAsFixed(3)}s')
                    else
                      _buildDetailRow(
                          'Duration', '${a.duration.toStringAsFixed(3)}s'),
                    if (a.expectedInterval != null)
                      _buildDetailRow('Expected Gap',
                          '${a.expectedInterval!.toStringAsFixed(3)}s'),
                    if (a.gapRatio != null)
                      _buildDetailRow('Gap Ratio',
                          '${a.gapRatio!.toStringAsFixed(2)}x'),
                    _buildDetailRow(
                        'Type',
                        a.isPtsGap
                            ? 'PTS GAP'
                            : (a.isVisualDiscontinuity
                                ? 'VISUAL DISCONTINUITY'
                                : a.type)),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: warningColor,
              ),
          ],
        ),
      ),
    );
  }

  // 4. CORRUPTED DETECTOR CARD
  Widget _buildCorruptedDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('CORRUPTED FRAME DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO CORRUPTED FRAMES DETECTED',
        subtext: 'No frame corruption or decode failures detected.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errColor = isDark ? Colors.redAccent : Colors.red[700]!;
    const expandKey = 'corrupted';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: AppColors.statusError.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '🔴 CORRUPTED FRAMES DETECTED',
              color: errColor,
              icon: Icons.broken_image_outlined,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Occurrences: $count corrupted frame range(s) detected',
              style: TextStyle(fontSize: 13, color: errColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Frame Range', '${a.frameStart} - ${a.frameEnd}'),
                    _buildDetailRow('Timestamp',
                        '${a.timestampStart.toStringAsFixed(2)}s - ${a.timestampEnd.toStringAsFixed(2)}s'),
                    _buildDetailRow(
                        'Error Type',
                        a.isCorruptedFrame
                            ? 'DECODE FAILURE'
                            : 'VISUAL ANOMALY'),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: errColor,
              ),
          ],
        ),
      ),
    );
  }

  // 5. MODIFICATION DETECTOR CARD
  Widget _buildModificationDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('MODIFICATION DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO FRAME MODIFICATION DETECTED',
        subtext: 'No suspicious spatial frame modifications detected.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errColor = isDark ? Colors.redAccent : Colors.red[700]!;
    const expandKey = 'modification';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: AppColors.statusError.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '🔴 FRAME MODIFICATION DETECTED',
              color: errColor,
              icon: Icons.edit_attributes_outlined,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Candidates: $count modification candidate(s)',
              style: TextStyle(fontSize: 13, color: errColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              final double scoreVal = a.score > 0
                  ? a.score
                  : (a.regionDifference ?? 0.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Frame Range', '${a.frameStart} - ${a.frameEnd}'),
                    _buildDetailRow('Timestamp',
                        '${a.timestampStart.toStringAsFixed(2)}s - ${a.timestampEnd.toStringAsFixed(2)}s'),
                    _buildDetailRow(
                        'Duration', '${a.duration.toStringAsFixed(2)}s'),
                    if (scoreVal > 0)
                      _buildDetailRow('Region Difference',
                          scoreVal.toStringAsFixed(4)),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: errColor,
              ),
          ],
        ),
      ),
    );
  }

  // 6. SCENE DETECTOR CARD
  Widget _buildSceneDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('SCENE DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO SCENE CHANGES DETECTED',
        subtext: 'No hard scene cuts detected.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sceneColor = isDark ? Colors.tealAccent : Colors.teal[700]!;
    const expandKey = 'scene';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: (isDark ? Colors.teal : Colors.teal[600]!).withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '🎬 SCENE CHANGES DETECTED',
              color: sceneColor,
              icon: Icons.movie_creation_outlined,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Scene Changes: $count scene cut(s)',
              style: TextStyle(fontSize: 13, color: sceneColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Frame', '${a.frameStart}'),
                    _buildDetailRow('Timestamp',
                        '${a.timestampStart.toStringAsFixed(2)}s'),
                    if (a.score > 0)
                      _buildDetailRow(
                          'Transition Score', a.score.toStringAsFixed(2)),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: sceneColor,
              ),
          ],
        ),
      ),
    );
  }

  // 7. COPY-MOVE FORGERY DETECTOR CARD
  Widget _buildCopyMoveDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('COPY-MOVE DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO COPY-MOVE TAMPERING DETECTED',
        subtext: 'No intra-frame cloned or repeated regions detected.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cmColor = isDark ? Colors.purpleAccent : Colors.purple[700]!;
    const expandKey = 'copy_move';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: (isDark ? Colors.purple : Colors.purple[600]!).withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '📋 COPY-MOVE TAMPERING CANDIDATES',
              color: cmColor,
              icon: Icons.content_copy_outlined,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Cloned Region Candidates: $count frame(s)',
              style: TextStyle(fontSize: 13, color: cmColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              final pairCount = a.rawJson['pair_count'] ?? a.regions.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Frame', '${a.frameStart}'),
                    _buildDetailRow('Timestamp', '${a.timestampStart.toStringAsFixed(2)}s'),
                    _buildDetailRow('Confidence', a.confidence),
                    if (pairCount != null && pairCount > 0)
                      _buildDetailRow('Matched Pairs', '$pairCount'),
                    if (a.score > 0)
                      _buildDetailRow('Tampering Score', a.score.toStringAsFixed(2)),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: cmColor,
              ),
          ],
        ),
      ),
    );
  }

  // 8. SPLICING DETECTOR CARD
  Widget _buildSpliceDetectorCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('SPLICING DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO SPLICING DETECTED',
        subtext: 'No inter-shot noise or lighting splice cuts detected.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spColor = isDark ? Colors.amberAccent : Colors.amber[800]!;
    const expandKey = 'splice';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: (isDark ? Colors.amber : Colors.amber[700]!).withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '✂️ VIDEO SPLICING CANDIDATES',
              color: spColor,
              icon: Icons.content_cut_outlined,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Splice Boundary Candidates: $count boundary cut(s)',
              style: TextStyle(fontSize: 13, color: spColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Boundary Frame', '${a.frameStart} → ${a.frameEnd}'),
                    _buildDetailRow('Timestamp', '${a.timestampStart.toStringAsFixed(2)}s'),
                    _buildDetailRow('Confidence', a.confidence),
                    if (a.signals.isNotEmpty)
                      _buildDetailRow('Forensic Signals', a.signals.keys.join(', ')),
                    if (a.score > 0)
                      _buildDetailRow('Splice Score', a.score.toStringAsFixed(2)),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: spColor,
              ),
          ],
        ),
      ),
    );
  }

  // 9. OBJECT MANIPULATION DETECTOR CARD
  Widget _buildObjectManipulationCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('OBJECT MANIPULATION DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NO OBJECT MANIPULATION DETECTED',
        subtext: 'No suspicious object insertion, removal, or inpainting residuals.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final objColor = isDark ? Colors.tealAccent : Colors.teal[800]!;
    const expandKey = 'object_manipulation';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: Colors.teal.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '🎯 OBJECT MANIPULATION CANDIDATES',
              color: objColor,
              icon: Icons.track_changes,
              statusBadgeText: 'DETECTED',
            ),
            const SizedBox(height: 12),
            Text(
              'Suspicious Object Changes: $count candidate sequence(s)',
              style: TextStyle(fontSize: 13, color: objColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Frame Range', '${a.frameStart} → ${a.frameEnd}'),
                    _buildDetailRow('Timestamp', '${a.timestampStart.toStringAsFixed(2)}s - ${a.timestampEnd.toStringAsFixed(2)}s'),
                    _buildDetailRow('Confidence', a.confidence),
                    if (a.evidence.isNotEmpty)
                      _buildDetailRow('Observation', a.evidence),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: objColor,
              ),
          ],
        ),
      ),
    );
  }

  // 10. COMPRESSION & RE-ENCODING ANALYSIS CARD
  Widget _buildCompressionForensicsCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('COMPRESSION FORENSICS');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ NORMAL COMPRESSION PROFILE',
        subtext: '8x8 CAG grid and GOP periodicity consistent with natural single encoding.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compColor = isDark ? Colors.blueAccent : Colors.blue[800]!;
    const expandKey = 'compression';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: Colors.blue.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '🗜️ COMPRESSION & RE-ENCODING',
              color: compColor,
              icon: Icons.compress,
              statusBadgeText: 'FLAGGED',
            ),
            const SizedBox(height: 12),
            Text(
              'Compression Inconsistencies: $count anomaly indicator(s)',
              style: TextStyle(fontSize: 13, color: compColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Anomaly Type', a.displayTitle),
                    _buildDetailRow('Timestamp', '${a.timestampStart.toStringAsFixed(2)}s'),
                    _buildDetailRow('Evidence', a.evidence),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: compColor,
              ),
          ],
        ),
      ),
    );
  }

  // 11. METADATA & CONTAINER TIMESTAMP CARD
  Widget _buildMetadataAuditCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('METADATA FORENSICS');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ METADATA CONSISTENCY VERIFIED',
        subtext: 'Container frames, nominal FPS, and timestamp continuity match decoded stream.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metaColor = isDark ? Colors.orangeAccent : Colors.orange[800]!;
    const expandKey = 'metadata';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: Colors.orange.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '📋 METADATA AUDIT DISCREPANCIES',
              color: metaColor,
              icon: Icons.info_outline,
              statusBadgeText: 'DISCREPANCY',
            ),
            const SizedBox(height: 12),
            Text(
              'Container/Stream Discrepancies: $count flagged variance(s)',
              style: TextStyle(fontSize: 13, color: metaColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Discrepancy', a.displayTitle),
                    _buildDetailRow('Details', a.evidence),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: metaColor,
              ),
          ],
        ),
      ),
    );
  }

  // 12. AUDIO/VIDEO SYNCHRONIZATION CARD
  Widget _buildAudioSyncCard({
    required bool isAvailable,
    required int count,
    required List<Anomaly> anomalies,
  }) {
    if (!isAvailable) {
      return _buildUnavailableCard('AUDIO / VIDEO SYNC DETECTOR');
    }

    if (count == 0 && anomalies.isEmpty) {
      return _buildCleanDetectorCard(
        title: '✓ AUDIO/VIDEO SYNC VERIFIED',
        subtext: 'A/V duration delta and energy envelope are within normal tolerances.',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audColor = isDark ? Colors.cyanAccent : Colors.cyan[800]!;
    const expandKey = 'audio_sync';
    final expanded = _isExpanded(expandKey);
    final visibleAnomalies = expanded ? anomalies : anomalies.take(3).toList();

    return ForensicCard(
      borderColor: Colors.cyan.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetectorCardHeader(
              title: '🔊 AUDIO / VIDEO SYNCHRONIZATION',
              color: audColor,
              icon: Icons.graphic_eq,
              statusBadgeText: 'ANOMALY',
            ),
            const SizedBox(height: 12),
            Text(
              'A/V Sync & Audio Cuts: $count flagged indicator(s)',
              style: TextStyle(fontSize: 13, color: audColor),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...visibleAnomalies.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Indicator', a.displayTitle),
                    _buildDetailRow('Timestamp', '${a.timestampStart.toStringAsFixed(2)}s'),
                    _buildDetailRow('Evidence', a.evidence),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),
            if (anomalies.length > 3)
              _buildExpandToggle(
                expandKey: expandKey,
                total: anomalies.length,
                expanded: expanded,
                color: audColor,
              ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPER WIDGETS
  // ================================================================

  // Expand / collapse toggle button shown at the bottom of a detector card
  // when there are more than 3 anomalies.
  Widget _buildExpandToggle({
    required String expandKey,
    required int total,
    required bool expanded,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: GestureDetector(
        onTap: () => _toggleDetector(expandKey),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                expanded
                    ? 'Show Less'
                    : 'Show All $total Detections',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectorCardHeader({
    required String title,
    required Color color,
    required IconData icon,
    required String statusBadgeText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            statusBadgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanDetectorCard({
    required String title,
    required String subtext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ForensicCard(
      borderColor: AppColors.statusSuccess.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 20,
              color: AppColors.statusSuccess,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.statusSuccess,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableCard(String detectorName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ForensicCard(
      borderColor: Colors.orange.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🟠 $detectorName DATA UNAVAILABLE',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Detector data was not returned by backend.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CLASSIFICATION NORMALIZER
  // ================================================================

  String _normalizeClassification(String value) {
    if (value.isEmpty) {
      return '';
    }

    final normalized = value
        .trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'LIKELY_AI_GENERATED':
      case 'AI_GENERATED':
      case 'AI_CONTENT_CANDIDATE':
      case 'AI_CONTENT':
      case 'AI_GENERATED_VIDEO':
        return 'LIKELY_AI_GENERATED';

      case 'LIKELY_REAL':
      case 'REAL':
      case 'NO_AI_SIGNAL':
      case 'NO_AI_SIGNAL_DETECTED':
      case 'NO_AI_DETECTED':
      case 'NO_AI_CONTENT':
        return 'LIKELY_REAL';

      case 'INCONCLUSIVE':
      case 'UNKNOWN':
      case 'UNDETERMINED':
      case 'INSUFFICIENT_EVIDENCE':
        return 'INCONCLUSIVE';

      default:
        return '';
    }
  }
}
