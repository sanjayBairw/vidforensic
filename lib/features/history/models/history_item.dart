class HistoryItem {
  final String jobId;
  final String filename;
  final String safeFilename;
  final String date;
  final String updatedAt;
  final String status;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final double? fps;
  final int? frameCount;
  final int anomalyCount;
  final int aiCandidates;
  final int modificationCandidates;
  final int missingFrameCandidates;
  final int visualDiscontinuities;
  final int corruptionCandidates;
  final int freezeCandidates;
  final int duplicateCandidates;
  final int sceneChanges;
  final bool reportAvailable;
  final bool resultAvailable;
  final String? errorMessage;

  HistoryItem({
    required this.jobId,
    required this.filename,
    this.safeFilename = '',
    required this.date,
    this.updatedAt = '',
    required this.status,
    this.durationSeconds,
    this.width,
    this.height,
    this.fps,
    this.frameCount,
    required this.anomalyCount,
    this.aiCandidates = 0,
    this.modificationCandidates = 0,
    this.missingFrameCandidates = 0,
    this.visualDiscontinuities = 0,
    this.corruptionCandidates = 0,
    this.freezeCandidates = 0,
    this.duplicateCandidates = 0,
    this.sceneChanges = 0,
    this.reportAvailable = false,
    this.resultAvailable = false,
    this.errorMessage,
  });

  String get overallForensicStatus {
    final statusUpper = status.toUpperCase();
    if (statusUpper == 'FAILED') {
      return 'ANALYSIS FAILED';
    }
    if (statusUpper == 'PROCESSING' || statusUpper == 'QUEUED' || statusUpper == 'UPLOADED') {
      return 'ANALYSIS IN PROGRESS';
    }
    if (aiCandidates > 0) {
      return 'AI CONTENT CANDIDATE';
    }
    if (anomalyCount > 0 ||
        modificationCandidates > 0 ||
        missingFrameCandidates > 0 ||
        corruptionCandidates > 0) {
      return 'FORENSIC REVIEW REQUIRED';
    }
    return 'NO FORENSIC ANOMALIES';
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final dateStr = json['created_at'] as String? ?? json['date'] as String? ?? '';
    final totalAnomalies = (json['total_anomalies'] as num?)?.toInt() ??
        (json['anomaly_count'] as num?)?.toInt() ??
        0;

    return HistoryItem(
      jobId: json['job_id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      safeFilename: json['safe_filename'] as String? ?? '',
      date: dateStr,
      updatedAt: json['updated_at'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      fps: (json['fps'] as num?)?.toDouble(),
      frameCount: (json['frame_count'] as num?)?.toInt(),
      anomalyCount: totalAnomalies,
      aiCandidates: (json['ai_candidates'] as num?)?.toInt() ?? 0,
      modificationCandidates: (json['modification_candidates'] as num?)?.toInt() ?? 0,
      missingFrameCandidates: (json['missing_frame_candidates'] as num?)?.toInt() ?? 0,
      visualDiscontinuities: (json['visual_discontinuities'] as num?)?.toInt() ?? 0,
      corruptionCandidates: (json['corruption_candidates'] as num?)?.toInt() ?? 0,
      freezeCandidates: (json['freeze_candidates'] as num?)?.toInt() ?? 0,
      duplicateCandidates: (json['duplicate_candidates'] as num?)?.toInt() ?? 0,
      sceneChanges: (json['scene_changes'] as num?)?.toInt() ?? 0,
      reportAvailable: json['report_available'] as bool? ?? false,
      resultAvailable: json['result_available'] as bool? ?? false,
      errorMessage: json['error_message'] as String? ?? json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'filename': filename,
      'safe_filename': safeFilename,
      'created_at': date,
      'date': date,
      'updated_at': updatedAt,
      'status': status,
      'duration_seconds': durationSeconds,
      'width': width,
      'height': height,
      'fps': fps,
      'frame_count': frameCount,
      'total_anomalies': anomalyCount,
      'anomaly_count': anomalyCount,
      'ai_candidates': aiCandidates,
      'modification_candidates': modificationCandidates,
      'missing_frame_candidates': missingFrameCandidates,
      'visual_discontinuities': visualDiscontinuities,
      'corruption_candidates': corruptionCandidates,
      'freeze_candidates': freezeCandidates,
      'duplicate_candidates': duplicateCandidates,
      'scene_changes': sceneChanges,
      'report_available': reportAvailable,
      'result_available': resultAvailable,
      'error_message': errorMessage,
    };
  }
}
