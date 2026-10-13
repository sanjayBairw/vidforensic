class UploadResponse {
  final String jobId;
  final String status;
  final String filename;
  final int fileSize;
  final String message;

  UploadResponse({
    required this.jobId,
    required this.status,
    required this.filename,
    required this.fileSize,
    required this.message,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      jobId: json['job_id'] as String? ?? '',
      status: json['status'] as String? ?? 'uploaded',
      filename: json['filename'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'status': status,
      'filename': filename,
      'file_size': fileSize,
      'message': message,
    };
  }
}

class AnalysisJob {
  final String jobId;
  final String filename;
  final String status; // uploaded | processing | completed | failed
  final int progress;  // 0 - 100
  final String? createdAt;
  final String? startedAt;
  final String? completedAt;
  final String? error;

  AnalysisJob({
    required this.jobId,
    required this.filename,
    required this.status,
    this.progress = 0,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.error,
  });

  bool get isProcessing => status == 'processing' || status == 'queued';

  factory AnalysisJob.fromJson(Map<String, dynamic> json) {
    return AnalysisJob(
      jobId: json['job_id'] ?? '',
      filename: json['filename'] ?? json['original_filename'] ?? '',
      status: json['status'] ?? 'uploaded',
      progress: json['progress'] is int ? json['progress'] : 0,
      createdAt: json['created_at'],
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'filename': filename,
      'status': status,
      'progress': progress,
      'created_at': createdAt,
      'started_at': startedAt,
      'completed_at': completedAt,
      'error': error,
    };
  }

  AnalysisJob copyWith({
    String? status,
    int? progress,
    String? startedAt,
    String? completedAt,
    String? error,
  }) {
    return AnalysisJob(
      jobId: jobId,
      filename: filename,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }
}
