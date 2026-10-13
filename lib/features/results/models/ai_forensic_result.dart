import 'package:flutter/foundation.dart';
import 'anomaly.dart';

class AiForensicResult {
  final String status;
  final double score;
  final String confidence;
  final String assessmentLabel;
  final int candidateCount;
  final List<Anomaly> segments;
  final Map<String, dynamic> signals;
  final List<String> limitations;

  // Dedicated AI classification layer
  final String classification;
  final double confidenceScore;
  final String evidenceQuality;
  final String modelProvider;
  final String summary;
  final List<String> indicators;
  final String naturalArtifactRisk;
  final bool reviewRequired;

  AiForensicResult({
    required this.status,
    required this.score,
    required this.confidence,
    required this.assessmentLabel,
    required this.candidateCount,
    required this.segments,
    required this.signals,
    required this.limitations,
    this.classification = 'INCONCLUSIVE',
    this.confidenceScore = 0.0,
    this.evidenceQuality = 'UNKNOWN',
    this.modelProvider = 'unknown',
    this.summary = '',
    this.indicators = const [],
    this.naturalArtifactRisk = 'UNKNOWN',
    this.reviewRequired = true,
  });

  factory AiForensicResult.fromJson(Map<String, dynamic> json) {
    // ============================================================
    // CANDIDATE / SEGMENT PARSING
    // ============================================================

    final List<Anomaly> parsedSegments = [];

    final dynamic segList =
        json['suspicious_segments'] ?? json['candidates'] ?? json['segments'];

    if (segList is List) {
      for (final item in segList) {
        if (item is Map<String, dynamic>) {
          parsedSegments.add(
            Anomaly.fromJson(item, defaultType: 'AI Content Candidate'),
          );
        }
      }
    }

    // ============================================================
    // SIGNALS
    // ============================================================

    final Map<String, dynamic> parsedSignals = {};

    if (json['signals'] is Map<String, dynamic>) {
      parsedSignals.addAll(
        Map<String, dynamic>.from(json['signals'] as Map<String, dynamic>),
      );
    } else if (json['signals_evaluated'] is List) {
      for (final signal in json['signals_evaluated'] as List) {
        parsedSignals[signal.toString()] = 'evaluated';
      }
    }

    // ============================================================
    // LIMITATIONS
    // ============================================================

    final List<String> parsedLimitations = [];

    if (json['limitations'] is List) {
      parsedLimitations.addAll(
        (json['limitations'] as List).map((item) => item.toString()).toList(),
      );
    }

    // ============================================================
    // AI ANALYSIS
    // ============================================================

    Map<String, dynamic> aiAnalysisMap = {};

    if (json['ai_analysis'] is Map<String, dynamic>) {
      aiAnalysisMap = Map<String, dynamic>.from(
        json['ai_analysis'] as Map<String, dynamic>,
      );
    }

    // ============================================================
    // CLASSIFICATION
    // ============================================================

    String parsedClass =
        aiAnalysisMap['classification']?.toString() ??
        json['classification']?.toString() ??
        json['assessment_label']?.toString() ??
        '';

    parsedClass = _normalizeClassification(parsedClass);

    // IMPORTANT:
    // Do NOT default missing AI data to LIKELY_REAL.
    // Missing AI data is INCONCLUSIVE.
    if (parsedClass.isEmpty) {
      parsedClass = 'INCONCLUSIVE';
    }

    // ============================================================
    // CONFIDENCE
    // ============================================================

    final double confScore =
        _toDouble(aiAnalysisMap['confidence']) ??
        _toDouble(json['confidence_score']) ??
        _toDouble(json['score']) ??
        _toDouble(json['ai_score']) ??
        0.0;

    // ============================================================
    // EVIDENCE QUALITY
    // ============================================================

    final String evidenceQuality =
        aiAnalysisMap['evidence_quality']?.toString() ??
        json['evidence_quality']?.toString() ??
        'UNKNOWN';

    // ============================================================
    // MODEL PROVIDER
    // ============================================================

    final String provider =
        aiAnalysisMap['model_provider']?.toString() ??
        json['model_provider']?.toString() ??
        'unknown';

    // ============================================================
    // SUMMARY
    // ============================================================

    final String summary =
        aiAnalysisMap['summary']?.toString() ??
        json['summary']?.toString() ??
        _defaultSummary(parsedClass);

    // ============================================================
    // INDICATORS
    // ============================================================

    final List<String> parsedIndicators = [];

    final dynamic rawIndicators =
        aiAnalysisMap['indicators'] ?? json['indicators'];

    if (rawIndicators is List) {
      parsedIndicators.addAll(rawIndicators.map((item) => item.toString()));
    }

    // ============================================================
    // NATURAL ARTIFACT RISK
    // ============================================================

    final String risk =
        aiAnalysisMap['natural_artifact_risk']?.toString() ??
        json['natural_artifact_risk']?.toString() ??
        'UNKNOWN';

    // ============================================================
    // REVIEW REQUIRED
    // ============================================================

    bool reviewRequired;

    if (aiAnalysisMap['review_required'] is bool) {
      reviewRequired = aiAnalysisMap['review_required'] as bool;
    } else if (json['review_required'] is bool) {
      reviewRequired = json['review_required'] as bool;
    } else {
      reviewRequired = parsedClass != 'LIKELY_REAL';
    }

    // ============================================================
    // CANDIDATE COUNT
    // ============================================================

    final int candidateCount =
        _toInt(json['candidate_count']) ??
        (parsedClass == 'LIKELY_AI_GENERATED' ? 1 : 0);

    // ============================================================
    // DEBUG
    // ============================================================

    assert(() {
      debugPrint('========== AI FORENSIC RESULT ==========');
      debugPrint('Classification : $parsedClass');
      debugPrint('Confidence     : $confScore');
      debugPrint('Evidence       : $evidenceQuality');
      debugPrint('Provider       : $provider');
      debugPrint('Candidates     : $candidateCount');
      debugPrint('========================================');
      return true;
    }());

    // ============================================================
    // RESULT
    // ============================================================

    return AiForensicResult(
      status: json['status']?.toString() ?? 'analyzed',
      score: confScore,
      confidence: evidenceQuality,
      assessmentLabel: parsedClass,
      candidateCount: candidateCount,
      segments: parsedSegments,
      signals: parsedSignals,
      limitations: parsedLimitations,
      classification: parsedClass,
      confidenceScore: confScore,
      evidenceQuality: evidenceQuality,
      modelProvider: provider,
      summary: summary,
      indicators: parsedIndicators,
      naturalArtifactRisk: risk,
      reviewRequired: reviewRequired,
    );
  }

  // ================================================================
  // CLASSIFICATION NORMALIZATION
  // ================================================================

  static String _normalizeClassification(String value) {
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

  // ================================================================
  // DEFAULT SUMMARY
  // ================================================================

  static String _defaultSummary(String classification) {
    switch (classification) {
      case 'LIKELY_AI_GENERATED':
        return 'AI-generated content indicators were detected.';

      case 'LIKELY_REAL':
        return 'No sufficient evidence of AI-generated content was detected.';

      default:
        return 'There is insufficient evidence to determine whether the video is AI-generated.';
    }
  }

  // ================================================================
  // SAFE NUMBER PARSERS
  // ================================================================

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  // ================================================================
  // JSON
  // ================================================================

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'score': score,
      'confidence': confidence,
      'assessment_label': assessmentLabel,
      'candidate_count': candidateCount,
      'suspicious_segments': segments.map((e) => e.toJson()).toList(),
      'signals': signals,
      'limitations': limitations,
      'ai_analysis': {
        'classification': classification,
        'confidence': confidenceScore,
        'evidence_quality': evidenceQuality,
        'model_provider': modelProvider,
        'summary': summary,
        'indicators': indicators,
        'natural_artifact_risk': naturalArtifactRisk,
        'review_required': reviewRequired,
      },
    };
  }
}
