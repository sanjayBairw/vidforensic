import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_provider.dart';
import '../models/comparison_models.dart';

class ComparisonState {
  final File? fileA;
  final File? fileB;
  final String? nameA;
  final String? nameB;
  final double timeOffset;
  final double sampleInterval;
  final bool isUploading;
  final double uploadProgress;
  final String? comparisonId;
  final String status; // initial, queued, processing, completed, failed
  final double progress; // 0.0 to 1.0
  final String? stage;
  final String? message;
  final String? error;
  final ComparisonResults? results;
  final int? selectedIntervalIndex;

  ComparisonState({
    this.fileA,
    this.fileB,
    this.nameA,
    this.nameB,
    this.timeOffset = 0.0,
    this.sampleInterval = 0.5,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.comparisonId,
    this.status = 'initial',
    this.progress = 0.0,
    this.stage,
    this.message,
    this.error,
    this.results,
    this.selectedIntervalIndex,
  });

  ComparisonState copyWith({
    File? fileA,
    File? fileB,
    String? nameA,
    String? nameB,
    double? timeOffset,
    double? sampleInterval,
    bool? isUploading,
    double? uploadProgress,
    String? comparisonId,
    String? status,
    double? progress,
    String? stage,
    String? message,
    String? error,
    ComparisonResults? results,
    int? selectedIntervalIndex,
    bool clearFileA = false,
    bool clearFileB = false,
  }) {
    return ComparisonState(
      fileA: clearFileA ? null : (fileA ?? this.fileA),
      fileB: clearFileB ? null : (fileB ?? this.fileB),
      nameA: clearFileA ? null : (nameA ?? this.nameA),
      nameB: clearFileB ? null : (nameB ?? this.nameB),
      timeOffset: timeOffset ?? this.timeOffset,
      sampleInterval: sampleInterval ?? this.sampleInterval,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      comparisonId: comparisonId ?? this.comparisonId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      stage: stage ?? this.stage,
      message: message ?? this.message,
      error: error,
      results: results ?? this.results,
      selectedIntervalIndex:
          selectedIntervalIndex ?? this.selectedIntervalIndex,
    );
  }
}

class ComparisonNotifier extends StateNotifier<ComparisonState> {
  final Ref ref;
  Timer? _pollingTimer;

  ComparisonNotifier(this.ref) : super(ComparisonState());

  Future<void> pickVideoA() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final name = result.files.single.name;
        state = state.copyWith(
          fileA: file,
          nameA: name,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to select Reference Video: $e');
    }
  }

  Future<void> pickVideoB() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final name = result.files.single.name;
        state = state.copyWith(
          fileB: file,
          nameB: name,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to select Suspected Video: $e');
    }
  }

  void clearVideoA() {
    state = state.copyWith(clearFileA: true);
  }

  void clearVideoB() {
    state = state.copyWith(clearFileB: true);
  }

  void setTimeOffset(double offset) {
    state = state.copyWith(timeOffset: offset);
  }

  void setSampleInterval(double interval) {
    state = state.copyWith(sampleInterval: interval);
  }

  void selectInterval(int? index) {
    state = state.copyWith(selectedIntervalIndex: index);
  }

  Future<void> startComparison() async {
    if (state.fileA == null || state.fileB == null) {
      state = state.copyWith(
          error: 'Please select both Reference Video (A) and Suspected Video (B).');
      return;
    }

    _pollingTimer?.cancel();
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.05,
      status: 'queued',
      progress: 0.05,
      stage: 'Uploading Videos',
      message: 'Uploading dual video payload to server...',
      error: null,
      results: null,
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final resp = await apiClient.createComparison(
        fileA: state.fileA!,
        fileB: state.fileB!,
        timeOffset: state.timeOffset,
        sampleInterval: state.sampleInterval,
        onProgress: (sent, total) {
          if (total > 0) {
            final p = sent / total;
            state = state.copyWith(uploadProgress: p);
          }
        },
      );

      final comparisonId = resp['comparison_id'] as String;
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        comparisonId: comparisonId,
        status: 'queued',
        stage: 'Queued',
        message: 'Comparison job created. Starting forensic comparison engine...',
      );

      _startPolling(comparisonId);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        status: 'failed',
        error: e.toString(),
      );
    }
  }

  void _startPolling(String comparisonId) {
    _pollingTimer?.cancel();
    _pollingTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      await pollStatus(comparisonId);
    });
  }

  Future<void> pollStatus(String comparisonId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getComparisonStatus(comparisonId);

      final statusStr = (res['status'] as String? ?? 'processing').toLowerCase();
      final num? progNum = res['progress'] as num?;

      double progress = 0.0;
      if (progNum != null) {
        double rawVal = progNum.toDouble();
        progress = (rawVal > 1.0 ? rawVal / 100.0 : rawVal).clamp(0.0, 1.0);
      }

      final stage = res['stage'] as String? ??
          res['message'] as String? ??
          'Comparing Videos';

      if (statusStr == 'completed') {
        _pollingTimer?.cancel();

        // Retrieve full comparison findings
        final resultsJson =
            await apiClient.getComparisonResults(comparisonId);
        final compResults = ComparisonResults.fromJson(resultsJson);

        state = state.copyWith(
          status: 'completed',
          progress: 1.0,
          stage: 'Completed',
          message: 'Forensic video comparison completed successfully.',
          results: compResults,
        );
      } else if (statusStr == 'failed') {
        _pollingTimer?.cancel();
        state = state.copyWith(
          status: 'failed',
          error: res['error'] as String? ?? 'Comparison analysis failed on backend.',
        );
      } else {
        state = state.copyWith(
          status: 'processing',
          progress: progress,
          stage: stage,
          message: res['message'] as String? ?? stage,
        );
      }
    } catch (e) {
      // Temporary network retry
      state = state.copyWith(
        message: 'Reconnecting to comparison service...',
      );
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  void reset() {
    _pollingTimer?.cancel();
    state = ComparisonState();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final comparisonProvider =
    StateNotifierProvider<ComparisonNotifier, ComparisonState>((ref) {
  return ComparisonNotifier(ref);
});
