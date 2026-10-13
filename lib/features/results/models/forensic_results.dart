import 'package:flutter/foundation.dart';

import 'anomaly.dart';
import 'ai_forensic_result.dart';

class VideoMetadata {
  final double duration;
  final double fps;
  final int totalFrames;
  final int width;
  final int height;

  VideoMetadata({
    required this.duration,
    required this.fps,
    required this.totalFrames,
    required this.width,
    required this.height,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : json;

    return VideoMetadata(
      duration:
          (meta['duration_seconds'] as num?)?.toDouble() ??
          (meta['duration'] as num?)?.toDouble() ??
          (json['duration_seconds'] as num?)?.toDouble() ??
          (json['video_duration'] as num?)?.toDouble() ??
          0.0,
      fps:
          (meta['fps'] as num?)?.toDouble() ??
          (json['fps'] as num?)?.toDouble() ??
          0.0,
      totalFrames:
          (meta['decoded_frames'] as num?)?.toInt() ??
          (meta['container_frames'] as num?)?.toInt() ??
          (meta['total_frames'] as num?)?.toInt() ??
          (json['decoded_frames'] as num?)?.toInt() ??
          0,
      width:
          (meta['width'] as num?)?.toInt() ??
          (json['width'] as num?)?.toInt() ??
          0,
      height:
          (meta['height'] as num?)?.toInt() ??
          (json['height'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'fps': fps,
      'total_frames': totalFrames,
      'width': width,
      'height': height,
    };
  }
}

class ForensicSummary {
  final int totalAnomalies;
  final int freezeFrames;
  final int duplicateFrames;
  final int missingFrames;
  final int corruptedFrames;
  final int visualDiscontinuities;
  final int visualAnomalies;
  final int missingPtsGaps;
  final int modificationCandidates;
  final int sceneChanges;
  final int aiContentCandidates;

  ForensicSummary({
    required this.totalAnomalies,
    required this.freezeFrames,
    required this.duplicateFrames,
    required this.missingFrames,
    required this.corruptedFrames,
    this.visualDiscontinuities = 0,
    this.visualAnomalies = 0,
    this.missingPtsGaps = 0,
    required this.modificationCandidates,
    required this.sceneChanges,
    required this.aiContentCandidates,
  });

  factory ForensicSummary.fromJson(
    Map<String, dynamic> json, {
    List<Anomaly>? anomalies,
  }) {
    final summaryMap = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : json;

    int total =
        (json['total_anomalies'] as num?)?.toInt() ??
        (summaryMap['total_anomalies'] as num?)?.toInt() ??
        0;

    int freeze =
        (summaryMap['FREEZE'] as num?)?.toInt() ??
        (summaryMap['freeze_frames'] as num?)?.toInt() ??
        0;

    int dup =
        (summaryMap['DUPLICATE'] as num?)?.toInt() ??
        (summaryMap['duplicate_frames'] as num?)?.toInt() ??
        0;

    int visDisc = (summaryMap['VISUAL_DISCONTINUITY'] as num?)?.toInt() ?? 0;

    int ptsGaps = (summaryMap['PTS_GAP'] as num?)?.toInt() ?? 0;

    int missing =
        visDisc +
        ptsGaps +
        ((summaryMap['MISSING_FRAME_CANDIDATE'] as num?)?.toInt() ??
            (summaryMap['missing_frames'] as num?)?.toInt() ??
            0);

    int corrFrames =
        (summaryMap['CORRUPTED_FRAME'] as num?)?.toInt() ??
        (summaryMap['corrupted_frames'] as num?)?.toInt() ??
        0;

    int visAnom =
        (summaryMap['VISUAL_ANOMALY_CANDIDATE'] as num?)?.toInt() ?? 0;

    int corrupted = corrFrames + visAnom;

    int mod =
        ((summaryMap['MODIFICATION_CANDIDATE'] as num?)?.toInt() ?? 0) +
        ((summaryMap['MODIFICATION'] as num?)?.toInt() ?? 0) +
        ((summaryMap['modification_candidates'] as num?)?.toInt() ?? 0);

    int scene =
        (summaryMap['SCENE_CHANGE'] as num?)?.toInt() ??
        (summaryMap['scene_changes'] as num?)?.toInt() ??
        0;

    int ai =
        (summaryMap['AI_CONTENT_CANDIDATE'] as num?)?.toInt() ??
        (summaryMap['ai_content_candidates'] as num?)?.toInt() ??
        0;

    // Compute dynamically from anomalies list if anomalies list is provided.
    if (anomalies != null && anomalies.isNotEmpty) {
      if (total == 0) {
        total = anomalies.length;
      }

      int calcVisDisc = 0;
      int calcPtsGaps = 0;
      int calcVisAnom = 0;
      int calcCorr = 0;
      int calcAi = 0;
      int calcMod = 0;
      int calcFreeze = 0;
      int calcDup = 0;
      int calcScene = 0;

      for (final a in anomalies) {
        if (a.isPtsGap) {
          calcPtsGaps++;
        } else if (a.isVisualDiscontinuity) {
          calcVisDisc++;
        } else if (a.isVisualAnomaly) {
          calcVisAnom++;
        } else if (a.isCorruptedFrame) {
          calcCorr++;
        } else if (a.isAiCandidate) {
          calcAi++;
        } else if (a.isModification) {
          calcMod++;
        } else if (a.type.contains('FREEZE')) {
          calcFreeze++;
        } else if (a.type.contains('DUPLICATE')) {
          calcDup++;
        } else if (a.type.contains('SCENE')) {
          calcScene++;
        }
      }

      if (visDisc == 0) {
        visDisc = calcVisDisc;
      }

      if (ptsGaps == 0) {
        ptsGaps = calcPtsGaps;
      }

      if (visAnom == 0) {
        visAnom = calcVisAnom;
      }

      if (corrFrames == 0) {
        corrFrames = calcCorr;
      }

      if (ai == 0) {
        ai = calcAi;
      }

      if (mod == 0) {
        mod = calcMod;
      }

      if (freeze == 0) {
        freeze = calcFreeze;
      }

      if (dup == 0) {
        dup = calcDup;
      }

      if (scene == 0) {
        scene = calcScene;
      }

      missing =
          visDisc +
          ptsGaps +
          (missing > (visDisc + ptsGaps) ? (missing - visDisc - ptsGaps) : 0);

      corrupted = corrFrames + visAnom;
    }

    final calculatedTotal = total > 0
        ? total
        : (freeze + dup + missing + corrupted + mod + scene + ai);

    return ForensicSummary(
      totalAnomalies: calculatedTotal,
      freezeFrames: freeze,
      duplicateFrames: dup,
      missingFrames: missing,
      corruptedFrames: corrupted,
      visualDiscontinuities: visDisc > 0
          ? visDisc
          : (missing - ptsGaps > 0 ? missing - ptsGaps : 0),
      visualAnomalies: visAnom > 0
          ? visAnom
          : (corrupted - corrFrames > 0 ? corrupted - corrFrames : 0),
      missingPtsGaps: ptsGaps,
      modificationCandidates: mod,
      sceneChanges: scene,
      aiContentCandidates: ai,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_anomalies': totalAnomalies,
      'freeze_frames': freezeFrames,
      'duplicate_frames': duplicateFrames,
      'missing_frames': missingFrames,
      'corrupted_frames': corruptedFrames,
      'modification_candidates': modificationCandidates,
      'scene_changes': sceneChanges,
      'ai_content_candidates': aiContentCandidates,
    };
  }
}

class ForensicResults {
  final String jobId;
  final String videoName;
  final String videoPath;
  final String status;
  final String createdAt;
  final VideoMetadata? metadata;
  final ForensicSummary? summary;
  final List<Anomaly> anomalies;
  final AiForensicResult? aiDetection;
  final Map<String, dynamic> rawDetectors;

  ForensicResults({
    required this.jobId,
    required this.videoName,
    this.videoPath = '',
    required this.status,
    required this.createdAt,
    this.metadata,
    this.summary,
    required this.anomalies,
    this.aiDetection,
    this.rawDetectors = const {},
  });

  factory ForensicResults.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // DETECTOR CONTAINERS
    // ============================================================

    final detectorsMap = json['detectors'] is Map<String, dynamic>
        ? json['detectors'] as Map<String, dynamic>
        : <String, dynamic>{};

    final evidenceMap = detectorsMap['evidence_results'] is Map<String, dynamic>
        ? detectorsMap['evidence_results'] as Map<String, dynamic>
        : (json['evidence_results'] is Map<String, dynamic>
              ? json['evidence_results'] as Map<String, dynamic>
              : <String, dynamic>{});

    final frameMap = detectorsMap['frame_analysis'] is Map<String, dynamic>
        ? detectorsMap['frame_analysis'] as Map<String, dynamic>
        : (json['frame_analysis'] is Map<String, dynamic>
              ? json['frame_analysis'] as Map<String, dynamic>
              : <String, dynamic>{});

    // ============================================================
    // AI RESULT EXTRACTION
    //
    // Accept all supported response shapes:
    //
    // 1. detectors.ai_results
    // 2. top-level ai_results
    // 3. top-level ai_detection
    // 4. top-level ai_analysis
    // 5. direct AI classification object
    //
    // This prevents a valid AI result from disappearing because
    // of a response nesting mismatch.
    // ============================================================

    Map<String, dynamic> aiMap = {};

    // 1. detectors.ai_results
    if (detectorsMap['ai_results'] is Map<String, dynamic>) {
      aiMap = detectorsMap['ai_results'] as Map<String, dynamic>;
    }
    // 2. top-level ai_results
    else if (json['ai_results'] is Map<String, dynamic>) {
      aiMap = json['ai_results'] as Map<String, dynamic>;
    }
    // 3. top-level ai_detection
    else if (json['ai_detection'] is Map<String, dynamic>) {
      aiMap = json['ai_detection'] as Map<String, dynamic>;
    }
    // 4. top-level ai_analysis
    else if (json['ai_analysis'] is Map<String, dynamic>) {
      aiMap = {
        'ai_analysis': json['ai_analysis'],
        'candidates': json['candidates'] ?? <dynamic>[],
        'candidate_count': json['candidate_count'] ?? 0,
        'assessment_label': json['assessment_label'],
        'score': json['score'],
        'confidence': json['confidence'],
      };
    }
    // 5. Direct classification object.
    else if (json['classification'] is String) {
      aiMap = {
        'ai_analysis': {
          'classification': json['classification'],
          'confidence': json['confidence'] ?? json['score'] ?? 0.0,
          'evidence_quality': json['evidence_quality'] ?? 'UNKNOWN',
          'model_provider': json['model_provider'] ?? 'local_model',
          'summary': json['summary'] ?? '',
          'indicators': json['indicators'] ?? <dynamic>[],
          'natural_artifact_risk': json['natural_artifact_risk'] ?? 'UNKNOWN',
          'review_required': json['review_required'] ?? false,
        },
        'candidates': json['candidates'] ?? <dynamic>[],
        'candidate_count': json['candidate_count'] ?? 0,
      };
    }

    // ============================================================
    // NORMALIZE DIRECT AI OBJECT
    //
    // If ai_results itself contains classification instead of
    // ai_analysis.classification, wrap it.
    // ============================================================

    if (aiMap.isNotEmpty &&
        !aiMap.containsKey('ai_analysis') &&
        aiMap.containsKey('classification')) {
      final originalAiMap = Map<String, dynamic>.from(aiMap);

      aiMap = {'ai_analysis': originalAiMap, ...originalAiMap};
    }

    // ============================================================
    // ANOMALIES
    // ============================================================

    final List<Anomaly> parsedAnomalies = [];

    final rawAnomalies =
        evidenceMap['anomalies'] ?? json['anomalies'] ?? json['evidence'];

    if (rawAnomalies is List) {
      for (final item in rawAnomalies) {
        if (item is Map<String, dynamic>) {
          parsedAnomalies.add(Anomaly.fromJson(item));
        }
      }
    }

    // ============================================================
    // VIDEO METADATA
    // ============================================================

    VideoMetadata? parsedMeta;

    if (frameMap.isNotEmpty) {
      parsedMeta = VideoMetadata.fromJson(frameMap);
    } else if (json['metadata'] is Map<String, dynamic>) {
      parsedMeta = VideoMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      );
    }

    // ============================================================
    // FORENSIC SUMMARY
    // ============================================================

    final parsedSummary = ForensicSummary.fromJson(
      evidenceMap.isNotEmpty ? evidenceMap : json,
      anomalies: parsedAnomalies,
    );

    // ============================================================
    // AI DETECTION
    // ============================================================

    AiForensicResult? aiRes;

    if (aiMap.isNotEmpty) {
      aiRes = AiForensicResult.fromJson(aiMap);
    }

    // ============================================================
    // DEBUG LOGGING
    // ============================================================

    assert(() {
      debugPrint('================================================');
      debugPrint('RAW FORENSIC API RESULTS PARSED');
      debugPrint('================================================');

      debugPrint('JOB ID: ${json['job_id']}');

      debugPrint('AI MAP FOUND: ${aiMap.isNotEmpty}');

      if (aiMap.isNotEmpty) {
        final analysis = aiMap['ai_analysis'] is Map<String, dynamic>
            ? aiMap['ai_analysis'] as Map<String, dynamic>
            : <String, dynamic>{};

        debugPrint(
          'AI CLASSIFICATION: '
          '${analysis['classification'] ?? aiMap['assessment_label'] ?? 'UNKNOWN'}',
        );

        debugPrint(
          'AI CANDIDATES: '
          '${aiMap['candidate_count'] ?? 0}',
        );

        debugPrint(
          'AI MODEL PROVIDER: '
          '${analysis['model_provider'] ?? 'UNKNOWN'}',
        );

        debugPrint(
          'AI EVIDENCE QUALITY: '
          '${analysis['evidence_quality'] ?? 'UNKNOWN'}',
        );
      } else {
        debugPrint('AI CLASSIFICATION: NOT FOUND');
      }

      debugPrint(
        'METADATA: '
        '${parsedMeta?.width}x${parsedMeta?.height}, '
        'FPS: ${parsedMeta?.fps}, '
        'Duration: ${parsedMeta?.duration}s, '
        'Frames: ${parsedMeta?.totalFrames}',
      );

      debugPrint(
        'TOTAL ANOMALIES: '
        '${parsedSummary.totalAnomalies}',
      );

      debugPrint(
        'SUMMARY COUNTS: '
        'AI=${parsedSummary.aiContentCandidates}, '
        'Corrupted=${parsedSummary.corruptedFrames}, '
        'Missing=${parsedSummary.missingFrames}, '
        'Mod=${parsedSummary.modificationCandidates}, '
        'Freeze=${parsedSummary.freezeFrames}, '
        'Dup=${parsedSummary.duplicateFrames}, '
        'Scene=${parsedSummary.sceneChanges}',
      );

      debugPrint('================================================');

      return true;
    }());

    // ============================================================
    // FINAL RESULT
    // ============================================================

    return ForensicResults(
      jobId: json['job_id'] as String? ?? '',
      videoName:
          json['filename'] as String? ?? json['video_name'] as String? ?? '',
      videoPath: json['video_path'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String? ?? '',
      metadata: parsedMeta,
      summary: parsedSummary,
      anomalies: parsedAnomalies,
      aiDetection: aiRes,
      rawDetectors: detectorsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'video_name': videoName,
      'video_path': videoPath,
      'status': status,
      'created_at': createdAt,
      'metadata': metadata?.toJson(),
      'summary': summary?.toJson(),
      'anomalies': anomalies.map((e) => e.toJson()).toList(),
      'ai_detection': aiDetection?.toJson(),
    };
  }
}
