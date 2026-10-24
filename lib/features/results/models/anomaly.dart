class AnomalyRegion {
  final int ymin;
  final int xmin;
  final int ymax;
  final int xmax;

  AnomalyRegion({
    required this.ymin,
    required this.xmin,
    required this.ymax,
    required this.xmax,
  });

  factory AnomalyRegion.fromJson(Map<String, dynamic> json) {
    return AnomalyRegion(
      ymin: (json['ymin'] as num?)?.toInt() ?? 0,
      xmin: (json['xmin'] as num?)?.toInt() ?? 0,
      ymax: (json['ymax'] as num?)?.toInt() ?? 0,
      xmax: (json['xmax'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => '[$ymin, $xmin, $ymax, $xmax]';
}

class Anomaly {
  final String detector;
  final String type;
  final String detectionType;
  final int frameStart;
  final int frameEnd;
  final int? frameBefore;
  final int? frameAfter;
  final double timestampStart;
  final double timestampEnd;
  final double? timestampBefore;
  final double? timestampAfter;
  final double? expectedInterval;
  final double? actualInterval;
  final double? gapRatio;
  final int estimatedMissing;
  final double? visualJumpScore;
  final double? regionDifference;
  final double duration;
  final double score;
  final String confidence;
  final Map<String, dynamic> signals;
  final String evidence;
  final List<String> regions;
  final Map<String, String> images;
  final Map<String, dynamic> rawJson;

  Anomaly({
    required this.detector,
    required this.type,
    this.detectionType = '',
    required this.frameStart,
    required this.frameEnd,
    this.frameBefore,
    this.frameAfter,
    required this.timestampStart,
    required this.timestampEnd,
    this.timestampBefore,
    this.timestampAfter,
    this.expectedInterval,
    this.actualInterval,
    this.gapRatio,
    this.estimatedMissing = 0,
    this.visualJumpScore,
    this.regionDifference,
    required this.duration,
    required this.score,
    required this.confidence,
    this.signals = const {},
    required this.evidence,
    this.regions = const [],
    this.images = const {},
    this.rawJson = const {},
  });

  String get id => '${detector}_${type}_${frameStart}_$timestampStart';

  String get anomalyType => type.isNotEmpty ? type : displayTitle;


  bool get isPtsGap => detectionType == 'PTS_GAP' || type == 'PTS_GAP' || (gapRatio != null && gapRatio! >= 1.5);
  bool get isVisualDiscontinuity => detectionType == 'VISUAL_DISCONTINUITY' || type == 'VISUAL_DISCONTINUITY';
  bool get isAiCandidate => type == 'AI_CONTENT_CANDIDATE';
  bool get isModification => type == 'MODIFICATION_CANDIDATE' || type == 'MODIFICATION';
  bool get isVisualAnomaly => type == 'VISUAL_ANOMALY_CANDIDATE';
  bool get isCorruptedFrame => type == 'CORRUPTED_FRAME';
  bool get isCopyMove => type == 'COPY_MOVE_CANDIDATE';
  bool get isSplice => type == 'SPLICE_CANDIDATE';
  bool get isForgeryCandidate => isCopyMove || isSplice;

  String get evidenceQuality => rawJson['evidence_quality']?.toString().toUpperCase() ?? confidence;
  String get naturalArtifactRisk => rawJson['natural_artifact_risk']?.toString().toUpperCase() ?? rawJson['contextual_risk']?.toString().toUpperCase() ?? 'LOW';
  int get independentSignalCount => (rawJson['independent_signal_count'] as num?)?.toInt() ?? 1;
  String get aiStatusText => rawJson['status']?.toString() ?? (isAiCandidate ? 'AI CONTENT CANDIDATE / FORENSIC REVIEW REQUIRED' : 'NO AI SIGNAL DETECTED');

  String get timestampStatusText {
    if (isPtsGap) return 'Abnormal PTS Gap';
    if (isVisualDiscontinuity) return 'Normal (No PTS Gap)';
    return 'Normal';
  }

  factory Anomaly.fromJson(Map<String, dynamic> json, {String? defaultType}) {
    Map<String, dynamic> parsedSignals = {};
    if (json['signals'] is Map<String, dynamic>) {
      parsedSignals = json['signals'] as Map<String, dynamic>;
    } else if (json['signals'] is List) {
      for (var i = 0; i < (json['signals'] as List).length; i++) {
        parsedSignals['sig_$i'] = json['signals'][i].toString();
      }
    }

    String parsedEvidence = '';
    if (json['evidence'] is String) {
      parsedEvidence = json['evidence'] as String;
    } else if (json['evidence'] is List) {
      parsedEvidence = (json['evidence'] as List).map((e) => e.toString()).join('. ');
    }

    List<String> parsedRegions = [];
    if (json['regions'] is List) {
      for (var item in json['regions'] as List) {
        parsedRegions.add(item.toString());
      }
    }

    Map<String, String> parsedImages = {};
    if (json['images'] is Map<String, dynamic>) {
      (json['images'] as Map<String, dynamic>).forEach((k, v) {
        parsedImages[k] = v.toString();
      });
    }

    final typeStr = json['type'] as String? ?? defaultType ?? json['anomaly_type'] as String? ?? 'ANOMALY';
    final detTypeStr = json['detection_type'] as String? ?? (typeStr == 'PTS_GAP' ? 'PTS_GAP' : (typeStr == 'VISUAL_DISCONTINUITY' ? 'VISUAL_DISCONTINUITY' : ''));

    return Anomaly(
      detector: json['detector'] as String? ?? 'forensic_detector',
      type: typeStr,
      detectionType: detTypeStr,
      frameStart: (json['frame_start'] as num?)?.toInt() ?? (json['frame_before'] as num?)?.toInt() ?? 0,
      frameEnd: (json['frame_end'] as num?)?.toInt() ?? (json['frame_after'] as num?)?.toInt() ?? 0,
      frameBefore: (json['frame_before'] as num?)?.toInt(),
      frameAfter: (json['frame_after'] as num?)?.toInt(),
      timestampStart: (json['timestamp_start'] as num?)?.toDouble() ?? (json['timestamp_before'] as num?)?.toDouble() ?? 0.0,
      timestampEnd: (json['timestamp_end'] as num?)?.toDouble() ?? (json['timestamp_after'] as num?)?.toDouble() ?? 0.0,
      timestampBefore: (json['timestamp_before'] as num?)?.toDouble(),
      timestampAfter: (json['timestamp_after'] as num?)?.toDouble(),
      expectedInterval: (json['expected_interval'] as num?)?.toDouble(),
      actualInterval: (json['actual_interval'] as num?)?.toDouble(),
      gapRatio: (json['gap_ratio'] as num?)?.toDouble(),
      estimatedMissing: (json['estimated_missing'] as num?)?.toInt() ?? (json['estimated_missing_frames'] as num?)?.toInt() ?? 0,
      visualJumpScore: (json['visual_jump_score'] as num?)?.toDouble() ?? (json['score'] as num?)?.toDouble(),
      regionDifference: (json['region_difference'] as num?)?.toDouble() ?? (json['changed_pixel_ratio'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      confidence: json['confidence']?.toString().toUpperCase() ?? 'MEDIUM',
      signals: parsedSignals,
      evidence: parsedEvidence,
      regions: parsedRegions,
      images: parsedImages,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detector': detector,
      'type': type,
      'frame_start': frameStart,
      'frame_end': frameEnd,
      'timestamp_start': timestampStart,
      'timestamp_end': timestampEnd,
      'duration': duration,
      'score': score,
      'confidence': confidence,
      'signals': signals,
      'evidence': evidence,
      'regions': regions,
      'images': images,
    };
  }

  String get displayTitle {
    switch (type) {
      case 'AI_CONTENT_CANDIDATE':
        return 'AI Content Candidate';
      case 'MODIFICATION_CANDIDATE':
        return 'Modification Candidate';
      case 'MISSING_FRAME_CANDIDATE':
        return 'Missing Frame Candidate';
      case 'CORRUPTED_FRAME':
        return 'Corrupted Frame';
      case 'FREEZE':
        return 'Freeze Frame Range';
      case 'DUPLICATE':
        return 'Duplicate Frame Range';
      case 'SCENE_CHANGE':
        return 'Scene Change Cut';
      case 'COPY_MOVE_CANDIDATE':
        return 'Copy-Move Forgery Candidate';
      case 'SPLICE_CANDIDATE':
        return 'Splice Boundary Candidate';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}
