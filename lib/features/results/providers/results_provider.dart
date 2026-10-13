import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_provider.dart';
import '../models/forensic_results.dart';
import '../models/anomaly.dart';

class ResultsState {
  final String? jobId;
  final bool isLoading;
  final ForensicResults? results;
  final List<Anomaly> evidenceItems;
  final String? error;

  const ResultsState({
    this.jobId,
    this.isLoading = false,
    this.results,
    this.evidenceItems = const [],
    this.error,
  });

  ResultsState copyWith({
    String? jobId,
    bool? isLoading,
    ForensicResults? results,
    List<Anomaly>? evidenceItems,
    String? error,
    bool clearResults = false,
  }) {
    return ResultsState(
      jobId: jobId ?? this.jobId,
      isLoading: isLoading ?? this.isLoading,

      // IMPORTANT:
      // When starting a new job, old results must be removed.
      results: clearResults ? null : (results ?? this.results),

      evidenceItems: clearResults
          ? const []
          : (evidenceItems ?? this.evidenceItems),

      error: error,
    );
  }
}

class ResultsNotifier extends StateNotifier<ResultsState> {
  final Ref ref;

  ResultsNotifier(this.ref) : super(const ResultsState());

  Future<void> fetchResults(String jobId) async {
    // ============================================================
    // IMPORTANT:
    // ALWAYS clear previous job's result before loading new job.
    // This prevents old AI result from appearing on a real video.
    // ============================================================

    state = state.copyWith(
      jobId: jobId,
      isLoading: true,
      error: null,
      clearResults: true,
    );

    try {
      final apiClient = ref.read(apiClientProvider);

      // ============================================================
      // FETCH MAIN FORENSIC RESULTS
      // ============================================================

      final resMap = await apiClient.getResults(jobId);

      final parsedResults = ForensicResults.fromJson(resMap);

      // ============================================================
      // SAFETY CHECK
      // ============================================================

      // Ignore response if somehow another job became active
      // while this request was running.
      if (state.jobId != jobId) {
        return;
      }

      // ============================================================
      // FETCH EVIDENCE ITEMS
      // ============================================================

      List<Anomaly> evidenceList = [];

      try {
        final evMap = await apiClient.getEvidence(jobId);

        final rawList = evMap['anomalies'] ?? evMap['evidence'];

        if (rawList is List) {
          evidenceList = rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => Anomaly.fromJson(item))
              .toList();
        } else {
          evidenceList = parsedResults.anomalies;
        }
      } catch (_) {
        // Evidence endpoint failed.
        // Use anomalies already included in main result.
        evidenceList = parsedResults.anomalies;
      }

      // ============================================================
      // FINAL JOB SAFETY CHECK
      // ============================================================

      if (state.jobId != jobId) {
        return;
      }

      // ============================================================
      // STORE ONLY CURRENT JOB RESULT
      // ============================================================

      state = state.copyWith(
        jobId: jobId,
        isLoading: false,
        results: parsedResults,
        evidenceItems: evidenceList,
        error: null,
      );

      // ============================================================
      // DEBUG
      // ============================================================

      final ai = parsedResults.aiDetection;

      debugPrint('==============================================');
      debugPrint('RESULTS PROVIDER');
      debugPrint('JOB ID          : $jobId');
      debugPrint('VIDEO           : ${parsedResults.videoName}');
      debugPrint('AI CLASS        : ${ai?.classification}');
      debugPrint('AI ASSESSMENT   : ${ai?.assessmentLabel}');
      debugPrint('AI CANDIDATES   : ${ai?.candidateCount}');
      debugPrint('AI CONFIDENCE   : ${ai?.confidenceScore}');
      debugPrint('==============================================');
    } catch (e) {
      // Only update state if this is still the active job.
      if (state.jobId != jobId) {
        return;
      }

      state = state.copyWith(
        jobId: jobId,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ================================================================
  // CLEAR RESULTS MANUALLY
  // ================================================================

  void clearResults() {
    state = const ResultsState();
  }
}

final resultsProvider = StateNotifierProvider<ResultsNotifier, ResultsState>((
  ref,
) {
  return ResultsNotifier(ref);
});
