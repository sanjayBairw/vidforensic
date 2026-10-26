import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/api_provider.dart';

class UploadState {
  final File? selectedFile;
  final double progress;
  final bool isUploading;
  final String? jobId;
  final String? videoName;
  final String? error;

  UploadState({
    this.selectedFile,
    this.progress = 0.0,
    this.isUploading = false,
    this.jobId,
    this.videoName,
    this.error,
  });

  UploadState copyWith({
    File? selectedFile,
    double? progress,
    bool? isUploading,
    String? jobId,
    String? videoName,
    String? error,
  }) {
    return UploadState(
      selectedFile: selectedFile ?? this.selectedFile,
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
      jobId: jobId ?? this.jobId,
      videoName: videoName ?? this.videoName,
      error: error,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final Ref ref;

  UploadNotifier(this.ref) : super(UploadState());

  Future<void> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final name = result.files.single.name;
        state = state.copyWith(
          selectedFile: file,
          videoName: name,
          progress: 0.0,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to select video: $e');
    }
  }

  void clearSelection() {
    state = UploadState();
  }

  Future<String?> uploadSelectedVideo() async {
    if (state.selectedFile == null) {
      state = state.copyWith(error: 'No video selected to upload.');
      return null;
    }

    state = state.copyWith(
      isUploading: true,
      progress: 0.0,
      error: null,
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.uploadVideo(
        file: state.selectedFile!,
        onProgress: (sent, total) {
          if (total > 0) {
            final p = sent / total;
            state = state.copyWith(progress: p);
          }
        },
      );

      final jobId = response['job_id'] as String?;
      final filename = response['filename'] as String? ?? state.videoName;

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        jobId: jobId,
        videoName: filename,
      );

      return jobId;
    } catch (e) {
      final message = e is ApiException ? e.message : e.toString();
      state = state.copyWith(
        isUploading: false,
        error: message,
      );
      return null;
    }
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref);
});
