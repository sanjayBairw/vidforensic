class VideoMetadata {
  final String label;
  final String filename;
  final int fileSize;
  final String sha256;
  final String container;
  final String codec;
  final int width;
  final int height;
  final String aspectRatio;
  final double fps;
  final int frameCount;
  final double duration;
  final String bitrate;
  final bool audioPresent;

  VideoMetadata({
    required this.label,
    required this.filename,
    required this.fileSize,
    required this.sha256,
    required this.container,
    required this.codec,
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.fps,
    required this.frameCount,
    required this.duration,
    required this.bitrate,
    required this.audioPresent,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      label: json['label'] as String? ?? '',
      filename: json['filename'] as String? ?? 'video.mp4',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      sha256: json['sha256'] as String? ?? '',
      container: json['container'] as String? ?? '',
      codec: json['codec'] as String? ?? 'Unknown',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      aspectRatio: json['aspect_ratio'] as String? ?? 'N/A',
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      frameCount: (json['frame_count'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      bitrate: json['bitrate'] as String? ?? 'N/A',
      audioPresent: json['audio_present'] as bool? ?? false,
    );
  }
}

class MetadataDiscrepancy {
  final String category;
  final String severity;
  final String detail;

  MetadataDiscrepancy({
    required this.category,
    required this.severity,
    required this.detail,
  });

  factory MetadataDiscrepancy.fromJson(Map<String, dynamic> json) {
    return MetadataDiscrepancy(
      category: json['category'] as String? ?? '',
      severity: json['severity'] as String? ?? 'LOW',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class MetadataComparison {
  final bool resolutionMatch;
  final bool fpsMatch;
  final bool durationMatch;
  final double durationDelta;
  final double sizeRatio;
  final List<MetadataDiscrepancy> discrepancies;
  final int totalDiscrepancies;

  MetadataComparison({
    required this.resolutionMatch,
    required this.fpsMatch,
    required this.durationMatch,
    required this.durationDelta,
    required this.sizeRatio,
    required this.discrepancies,
    required this.totalDiscrepancies,
  });

  factory MetadataComparison.fromJson(Map<String, dynamic> json) {
    final rawDisc = json['discrepancies'] as List<dynamic>? ?? [];
    return MetadataComparison(
      resolutionMatch: json['resolution_match'] as bool? ?? true,
      fpsMatch: json['fps_match'] as bool? ?? true,
      durationMatch: json['duration_match'] as bool? ?? true,
      durationDelta: (json['duration_delta'] as num?)?.toDouble() ?? 0.0,
      sizeRatio: (json['size_ratio'] as num?)?.toDouble() ?? 1.0,
      discrepancies:
          rawDisc.map((d) => MetadataDiscrepancy.fromJson(d)).toList(),
      totalDiscrepancies: (json['total_discrepancies'] as num?)?.toInt() ?? 0,
    );
  }
}

class SuspiciousInterval {
  final String intervalId;
  final int intervalIndex;
  final double startTimeA;
  final double endTimeA;
  final double startTimeB;
  final double endTimeB;
  final double duration;
  final int sampleCount;
  final double minSsim;
  final double maxDifference;
  final double averageMae;
  final double averagePhashDistance;
  final String severity;
  final String explanation;
  final double peakTimestampA;
  final double peakTimestampB;
  final Map<String, String> evidenceFiles;

  SuspiciousInterval({
    required this.intervalId,
    required this.intervalIndex,
    required this.startTimeA,
    required this.endTimeA,
    required this.startTimeB,
    required this.endTimeB,
    required this.duration,
    required this.sampleCount,
    required this.minSsim,
    required this.maxDifference,
    required this.averageMae,
    required this.averagePhashDistance,
    required this.severity,
    required this.explanation,
    required this.peakTimestampA,
    required this.peakTimestampB,
    required this.evidenceFiles,
  });

  factory SuspiciousInterval.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['evidence_files'] is Map
        ? (json['evidence_files'] as Map)
        : const {};
    final Map<String, String> files = {};
    rawFiles.forEach((k, v) {
      files[k.toString()] = v.toString();
    });

    return SuspiciousInterval(
      intervalId: json['interval_id'] as String? ?? 'INT_01',
      intervalIndex: (json['interval_index'] as num?)?.toInt() ?? 1,
      startTimeA: (json['start_time_a'] as num?)?.toDouble() ?? 0.0,
      endTimeA: (json['end_time_a'] as num?)?.toDouble() ?? 0.0,
      startTimeB: (json['start_time_b'] as num?)?.toDouble() ?? 0.0,
      endTimeB: (json['end_time_b'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 1,
      minSsim: (json['min_ssim'] as num?)?.toDouble() ?? 1.0,
      maxDifference: (json['max_difference'] as num?)?.toDouble() ?? 0.0,
      averageMae: (json['average_mae'] as num?)?.toDouble() ?? 0.0,
      averagePhashDistance:
          (json['average_phash_distance'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'LOW',
      explanation: json['explanation'] as String? ?? '',
      peakTimestampA: (json['peak_timestamp_a'] as num?)?.toDouble() ?? 0.0,
      peakTimestampB: (json['peak_timestamp_b'] as num?)?.toDouble() ?? 0.0,
      evidenceFiles: files,
    );
  }
}

class TimelineSample {
  final int sampleIdx;
  final double timestampA;
  final double timestampB;
  final double ssim;
  final double mae;
  final double phashDistance;
  final double histSimilarity;
  final double differenceScore;
  final bool isAnomalous;

  TimelineSample({
    required this.sampleIdx,
    required this.timestampA,
    required this.timestampB,
    required this.ssim,
    required this.mae,
    required this.phashDistance,
    required this.histSimilarity,
    required this.differenceScore,
    required this.isAnomalous,
  });

  factory TimelineSample.fromJson(Map<String, dynamic> json) {
    return TimelineSample(
      sampleIdx: (json['sample_idx'] as num?)?.toInt() ?? 0,
      timestampA: (json['timestamp_a'] as num?)?.toDouble() ?? 0.0,
      timestampB: (json['timestamp_b'] as num?)?.toDouble() ?? 0.0,
      ssim: (json['ssim'] as num?)?.toDouble() ?? 1.0,
      mae: (json['mae'] as num?)?.toDouble() ?? 0.0,
      phashDistance: (json['phash_distance'] as num?)?.toDouble() ?? 0.0,
      histSimilarity: (json['hist_similarity'] as num?)?.toDouble() ?? 1.0,
      differenceScore: (json['difference_score'] as num?)?.toDouble() ?? 0.0,
      isAnomalous: json['is_anomalous'] as bool? ?? false,
    );
  }
}

class ComparisonSummary {
  final double overallSimilarityPercentage;
  final String verdict;
  final String verdictLabel;
  final String severity;
  final int totalSamplesAnalyzed;
  final int totalSuspiciousIntervals;
  final double overlapDuration;
  final double averageSsim;
  final double averageMae;
  final double averagePhashDistance;
  final double averageHistogramSimilarity;

  ComparisonSummary({
    required this.overallSimilarityPercentage,
    required this.verdict,
    required this.verdictLabel,
    required this.severity,
    required this.totalSamplesAnalyzed,
    required this.totalSuspiciousIntervals,
    required this.overlapDuration,
    required this.averageSsim,
    required this.averageMae,
    required this.averagePhashDistance,
    required this.averageHistogramSimilarity,
  });

  factory ComparisonSummary.fromJson(Map<String, dynamic> json) {
    return ComparisonSummary(
      overallSimilarityPercentage:
          (json['overall_similarity_percentage'] as num?)?.toDouble() ?? 100.0,
      verdict: json['verdict'] as String? ?? 'MATCHING_CONTENT',
      verdictLabel: json['verdict_label'] as String? ??
          'MATCHING VIDEOS - NO SIGNIFICANT DISCREPANCIES',
      severity: json['severity'] as String? ?? 'NONE',
      totalSamplesAnalyzed:
          (json['total_samples_analyzed'] as num?)?.toInt() ?? 0,
      totalSuspiciousIntervals:
          (json['total_suspicious_intervals'] as num?)?.toInt() ?? 0,
      overlapDuration: (json['overlap_duration'] as num?)?.toDouble() ?? 0.0,
      averageSsim: (json['average_ssim'] as num?)?.toDouble() ?? 1.0,
      averageMae: (json['average_mae'] as num?)?.toDouble() ?? 0.0,
      averagePhashDistance:
          (json['average_phash_distance'] as num?)?.toDouble() ?? 0.0,
      averageHistogramSimilarity:
          (json['average_histogram_similarity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ComparisonResults {
  final String comparisonId;
  final String generatedAt;
  final double timeOffset;
  final double sampleInterval;
  final ComparisonSummary summary;
  final VideoMetadata videoA;
  final VideoMetadata videoB;
  final MetadataComparison metadataComparison;
  final List<Map<String, dynamic>> unmatchedIntervals;
  final List<SuspiciousInterval> suspiciousIntervals;
  final List<TimelineSample> timelineSamples;
  final Map<String, dynamic> detectorCorrelations;
  final List<String> limitations;

  ComparisonResults({
    required this.comparisonId,
    required this.generatedAt,
    required this.timeOffset,
    required this.sampleInterval,
    required this.summary,
    required this.videoA,
    required this.videoB,
    required this.metadataComparison,
    required this.unmatchedIntervals,
    required this.suspiciousIntervals,
    required this.timelineSamples,
    required this.detectorCorrelations,
    required this.limitations,
  });

  factory ComparisonResults.fromJson(Map<String, dynamic> json) {
    final cfg = json['configuration'] as Map<String, dynamic>? ?? {};
    final rawIntervals = json['suspicious_intervals'] as List<dynamic>? ?? [];
    final rawSamples = json['timeline_samples'] as List<dynamic>? ?? [];
    final rawUnmatched = json['unmatched_intervals'] as List<dynamic>? ?? [];
    final rawLimitations = json['limitations'] as List<dynamic>? ?? [];

    return ComparisonResults(
      comparisonId: json['comparison_id'] as String? ?? '',
      generatedAt: json['generated_at'] as String? ?? '',
      timeOffset: (cfg['time_offset'] as num?)?.toDouble() ?? 0.0,
      sampleInterval: (cfg['sample_interval'] as num?)?.toDouble() ?? 0.5,
      summary: ComparisonSummary.fromJson(
          Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      videoA: VideoMetadata.fromJson(
          Map<String, dynamic>.from(json['video_a'] as Map? ?? {})),
      videoB: VideoMetadata.fromJson(
          Map<String, dynamic>.from(json['video_b'] as Map? ?? {})),
      metadataComparison: MetadataComparison.fromJson(
          Map<String, dynamic>.from(json['metadata_comparison'] as Map? ?? {})),
      unmatchedIntervals: rawUnmatched
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      suspiciousIntervals: rawIntervals
          .map((i) => SuspiciousInterval.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      timelineSamples: rawSamples
          .map((s) => TimelineSample.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      detectorCorrelations: json['detector_correlations'] is Map
          ? Map<String, dynamic>.from(json['detector_correlations'] as Map)
          : {},
      limitations: rawLimitations.map((l) => l.toString()).toList(),
    );
  }
}

