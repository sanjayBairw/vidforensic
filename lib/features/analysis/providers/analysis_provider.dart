import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_provider.dart';
import '../../../core/network/api_exceptions.dart';

class AnalysisState {
  final String? jobId;
  final String status; // initial, queued, processing, completed, failed
  final double progress; // 0.0 to 1.0
  final String? currentStage;
  final String? message;
  final String? error;
  final Map<String, dynamic>? rawStatus;

  AnalysisState({
    this.jobId,
    this.status = 'initial',
    this.progress = 0.0,
    this.currentStage,
    this.message,
    this.error,
    this.rawStatus,
  });

  AnalysisState copyWith({
    String? jobId,
    String? status,
    double? progress,
    String? currentStage,
    String? message,
    String? error,
    Map<String, dynamic>? rawStatus,
  }) {
    return AnalysisState(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStage: currentStage ?? this.currentStage,
      message: message ?? this.message,
      error: error,
      rawStatus: rawStatus ?? this.rawStatus,
    );
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final Ref ref;
  Timer? _pollingTimer;
  int _consecutiveNotFoundCount = 0;

  AnalysisNotifier(this.ref) : super(AnalysisState());

  void initJob(String jobId) {
    _pollingTimer?.cancel();
    _consecutiveNotFoundCount = 0;
    state = AnalysisState(
      jobId: jobId,
      status: 'queued',
      progress: 0.05,
      currentStage: 'Initializing',
    );
  }

  Future<void> startAnalysis(String jobId) async {
    initJob(jobId);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.startAnalysis(jobId);
      
      // Start polling status every 1.5 seconds
      _startPolling(jobId);
    } catch (e) {
      state = state.copyWith(
        status: 'failed',
        error: e.toString(),
      );
    }
  }

  void _startPolling(String jobId) {
    _pollingTimer?.cancel();
    _consecutiveNotFoundCount = 0;
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      await pollStatus(jobId);
    });
  }

  Future<void> pollStatus(String jobId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getStatus(jobId);
      _consecutiveNotFoundCount = 0;

      final statusStr = (res['status'] as String? ?? 'processing').toLowerCase();
      final num? progNum = res['progress'] as num?;
      
      // Normalize progress to 0.0 - 1.0 (backend returns 0..100)
      double progress = 0.0;
      if (progNum != null) {
        double rawVal = progNum.toDouble();
        progress = (rawVal > 1.0 ? rawVal / 100.0 : rawVal).clamp(0.0, 1.0);
      }
      
      final stage = res['stage'] as String? ?? res['message'] as String? ?? 'Processing';

      if (statusStr == 'completed') {
        _pollingTimer?.cancel();
        state = state.copyWith(
          status: 'completed',
          progress: 1.0,
          currentStage: 'Completed',
          message: 'Forensic analysis completed successfully.',
          rawStatus: res,
        );
      } else if (statusStr == 'failed') {
        _pollingTimer?.cancel();
        state = state.copyWith(
          status: 'failed',
          error: res['error'] as String? ?? 'Analysis job failed on backend.',
          rawStatus: res,
        );
      } else {
        state = state.copyWith(
          status: 'processing',
          progress: progress,
          currentStage: stage,
          rawStatus: res,
        );
      }
    } on JobNotFoundException {
      _consecutiveNotFoundCount++;
      if (_consecutiveNotFoundCount >= 3) {
        _pollingTimer?.cancel();
        state = state.copyWith(
          status: 'failed',
          error: 'Analysis job not found on server (container restarted or job expired). Please upload the video again.',
        );
      } else {
        state = state.copyWith(
          message: 'Connecting to backend status service ($_consecutiveNotFoundCount/3)...',
        );
      }
    } catch (e) {
      // Don't immediately cancel timer on temporary network hiccup
      state = state.copyWith(
        message: 'Reconnecting to backend status service...',
      );
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier(ref);
});
