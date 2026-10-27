import 'package:flutter_test/flutter_test.dart';
import 'package:vidforensic/shared/models/analysis_job.dart';
import 'package:vidforensic/features/results/models/anomaly.dart';
import 'package:vidforensic/features/results/models/ai_forensic_result.dart';
import 'package:vidforensic/features/results/models/forensic_results.dart';
import 'package:vidforensic/features/history/models/history_item.dart';

void main() {
  group('Dart Models Parsing Tests', () {
    test('UploadResponse and AnalysisJob parsing', () {
      final uploadJson = {
        'job_id': 'job_test_123',
        'status': 'queued',
        'filename': 'normal_test.mp4',
        'file_size': 1048576,
        'message': 'File uploaded successfully'
      };

      final uploadResp = UploadResponse.fromJson(uploadJson);
      expect(uploadResp.jobId, 'job_test_123');
      expect(uploadResp.status, 'queued');
      expect(uploadResp.filename, 'normal_test.mp4');

      final jobJson = {
        'job_id': 'job_test_123',
        'filename': 'normal_test.mp4',
        'status': 'processing',
        'created_at': '2026-09-24T12:00:00Z',
        'video_path': 'uploads/normal_test.mp4'
      };

      final job = AnalysisJob.fromJson(jobJson);
      expect(job.jobId, 'job_test_123');
      expect(job.status, 'processing');
      expect(job.isProcessing, isTrue);
    });

    test('HistoryItem JSON parsing and overallForensicStatus classification', () {
      final historyJson = {
        'job_id': 'job_hist_001',
        'filename': 'ai_realistic_test.mp4',
        'safe_filename': 'ai_realistic_test.mp4',
        'created_at': '2026-09-26T18:00:00Z',
        'updated_at': '2026-09-26T18:05:00Z',
        'status': 'COMPLETED',
        'duration_seconds': 10.0,
        'width': 1920,
        'height': 1080,
        'fps': 30.0,
        'frame_count': 300,
        'total_anomalies': 4,
        'ai_candidates': 2,
        'modification_candidates': 1,
        'missing_frame_candidates': 1,
        'report_available': true,
        'result_available': true
      };

      final item = HistoryItem.fromJson(historyJson);
      expect(item.jobId, 'job_hist_001');
      expect(item.filename, 'ai_realistic_test.mp4');
      expect(item.status, 'COMPLETED');
      expect(item.anomalyCount, 4);
      expect(item.aiCandidates, 2);
      expect(item.overallForensicStatus, 'AI CONTENT CANDIDATE');

      // Test Forensic Review Required
      final reviewItem = HistoryItem.fromJson({
        'job_id': 'job_hist_002',
        'filename': 'modification_test.mp4',
        'status': 'COMPLETED',
        'total_anomalies': 2,
        'ai_candidates': 0,
        'modification_candidates': 2
      });
      expect(reviewItem.overallForensicStatus, 'FORENSIC REVIEW REQUIRED');

      // Test No Forensic Anomalies
      final cleanItem = HistoryItem.fromJson({
        'job_id': 'job_hist_003',
        'filename': 'normal_test.mp4',
        'status': 'COMPLETED',
        'total_anomalies': 0,
        'ai_candidates': 0
      });
      expect(cleanItem.overallForensicStatus, 'NO FORENSIC ANOMALIES');

      // Test Processing State
      final processingItem = HistoryItem.fromJson({
        'job_id': 'job_hist_004',
        'filename': 'processing_test.mp4',
        'status': 'PROCESSING'
      });
      expect(processingItem.overallForensicStatus, 'ANALYSIS IN PROGRESS');
    });

    test('Anomaly parsing', () {
      final anomalyJson = {
        'detector': 'modification_detector',
        'type': 'MODIFICATION CANDIDATE',
        'frame_start': 70,
        'frame_end': 76,
        'timestamp_start': 2.80,
        'timestamp_end': 3.04,
        'duration': 0.24,
        'score': 0.85,
        'confidence': 'MEDIUM',
        'signals': {'spatial_std': 12.5},
        'evidence': 'Visual temporal disruption detected between frames 70-76',
        'regions': ['[10, 20, 100, 200]']
      };

      final anomaly = Anomaly.fromJson(anomalyJson);
      expect(anomaly.detector, 'modification_detector');
      expect(anomaly.anomalyType, 'MODIFICATION CANDIDATE');
      expect(anomaly.frameStart, 70);
      expect(anomaly.frameEnd, 76);
      expect(anomaly.confidence, 'MEDIUM');
      expect(anomaly.signals['spatial_std'], 12.5);
    });

    test('AiForensicResult parsing and strict terminology', () {
      final aiJson = {
        'status': 'analyzed',
        'score': 0.72,
        'confidence': 'HIGH',
        'assessment_label': 'AI Content Candidate',
        'candidate_count': 1,
        'suspicious_segments': [
          {
            'detector': 'ai_detector',
            'type': 'AI Content Candidate',
            'frame_start': 10,
            'frame_end': 40,
            'timestamp_start': 0.40,
            'timestamp_end': 1.60,
            'duration': 1.20,
            'score': 0.75,
            'confidence': 'HIGH',
            'signals': {'fft_high_freq_ratio': 0.45},
            'evidence': 'Spectral anomaly detected',
          }
        ],
        'signals': {'fft_anomaly': 0.45, 'lbp_residual': 0.12},
        'limitations': [
          'High compression artifacts may influence statistical metrics.'
        ]
      };

      final aiRes = AiForensicResult.fromJson(aiJson);
      expect(aiRes.score, 0.72);
      expect(aiRes.confidence, 'HIGH');
      expect(aiRes.assessmentLabel, 'LIKELY_AI_GENERATED');
      expect(aiRes.candidateCount, 1);
      expect(aiRes.segments.first.anomalyType, 'AI Content Candidate');
      expect(aiRes.limitations, contains('High compression artifacts may influence statistical metrics.'));
    });

    test('ForensicResults and ForensicSummary parsing', () {
      final fullResultsJson = {
        'job_id': 'job_456',
        'video_name': 'ai_realistic_test.mp4',
        'video_path': 'uploads/ai_realistic_test.mp4',
        'status': 'completed',
        'created_at': '2026-09-24T12:10:00Z',
        'metadata': {
          'duration': 5.0,
          'fps': 25.0,
          'total_frames': 125,
          'width': 1280,
          'height': 720
        },
        'summary': {
          'total_anomalies': 3,
          'freeze_frames': 0,
          'duplicate_frames': 0,
          'missing_frames': 1,
          'corrupted_frames': 0,
          'modification_candidates': 1,
          'scene_changes': 0,
          'ai_content_candidates': 1
        },
        'anomalies': [
          {
            'detector': 'ai_detector',
            'type': 'AI Content Candidate',
            'frame_start': 0,
            'frame_end': 50,
            'timestamp_start': 0.0,
            'timestamp_end': 2.0,
            'duration': 2.0,
            'score': 0.88,
            'confidence': 'HIGH',
            'signals': {},
            'evidence': 'Spectral high frequency energy attenuation'
          }
        ]
      };

      final results = ForensicResults.fromJson(fullResultsJson);
      expect(results.jobId, 'job_456');
      expect(results.videoName, 'ai_realistic_test.mp4');
      expect(results.summary?.totalAnomalies, 3);
      expect(results.summary?.aiContentCandidates, 1);
      expect(results.anomalies.length, 1);
      expect(results.metadata?.fps, 25.0);
    });

    test('ForensicResults parsing real FastAPI detectors structure', () {
      final backendResultsJson = {
        'job_id': 'c30aa60b-0e80-40d4-98fa-a0cfb5dd47fd',
        'filename': 'gemini_generated_video_e9f8f511.mp4',
        'status': 'completed',
        'created_at': '2026-09-25T10:00:00Z',
        'detectors': {
          'frame_analysis': {
            'video': 'storage/uploads/gemini_generated_video_e9f8f511.mp4',
            'metadata': {
              'resolution': '1280x720',
              'width': 1280,
              'height': 720,
              'fps': 24.0,
              'container_frames': 240,
              'decoded_frames': 240,
              'duration_seconds': 10.0
            }
          },
          'evidence_results': {
            'total_anomalies': 12,
            'summary': {
              'FREEZE': 0,
              'DUPLICATE': 0,
              'MISSING_FRAME_CANDIDATE': 4,
              'CORRUPTED_FRAME': 0,
              'VISUAL_ANOMALY_CANDIDATE': 2,
              'MODIFICATION_CANDIDATE': 2,
              'SCENE_CHANGE': 0,
              'AI_CONTENT_CANDIDATE': 4
            },
            'anomalies': [
              {
                'detector': 'ai_detector',
                'type': 'AI_CONTENT_CANDIDATE',
                'frame_start': 2,
                'frame_end': 120,
                'timestamp_start': 0.0833,
                'timestamp_end': 5.0,
                'duration': 4.9167,
                'score': 0.6159,
                'confidence': 'MEDIUM',
                'signals': ['fft_spectral_grid_artifact', 'temporal_warp_flicker'],
                'evidence': ['FFT spectral grid artifacts detected']
              },
              {
                'detector': 'missing_detector',
                'type': 'MISSING_FRAME_CANDIDATE',
                'detection_type': 'VISUAL_DISCONTINUITY',
                'frame_start': 121,
                'frame_end': 122,
                'timestamp_start': 5.0833,
                'timestamp_end': 5.125,
                'duration': 0.0417,
                'score': 0.1736,
                'confidence': 'MEDIUM',
                'signals': ['visual_continuity_discontinuity'],
                'evidence': ['Visual continuity anomaly detected']
              }
            ]
          }
        }
      };

      final results = ForensicResults.fromJson(backendResultsJson);
      expect(results.jobId, 'c30aa60b-0e80-40d4-98fa-a0cfb5dd47fd');
      expect(results.videoName, 'gemini_generated_video_e9f8f511.mp4');
      expect(results.metadata?.duration, 10.0);
      expect(results.metadata?.fps, 24.0);
      expect(results.metadata?.totalFrames, 240);
      expect(results.metadata?.width, 1280);
      expect(results.metadata?.height, 720);

      expect(results.summary?.totalAnomalies, 12);
      expect(results.summary?.aiContentCandidates, 4);
      expect(results.summary?.missingFrames, 4);
      expect(results.summary?.corruptedFrames, 2);
      expect(results.summary?.modificationCandidates, 2);
      expect(results.summary?.freezeFrames, 0);
      expect(results.summary?.duplicateFrames, 0);
      expect(results.summary?.sceneChanges, 0);
    });

    test('Extended Forgery Anomaly getters and ForensicSummary parsing', () {
      final anomaliesJson = [
        {
          'detector': 'object_manipulation_detector',
          'type': 'OBJECT_MANIPULATION_CANDIDATE',
          'frame_start': 10,
          'frame_end': 20,
          'timestamp_start': 0.4,
          'timestamp_end': 0.8,
          'duration': 0.4,
          'score': 0.88,
          'confidence': 'HIGH',
          'signals': {'discontinuity_score': 0.82},
          'evidence': 'Unnatural boundary discontinuity around tracked component',
        },
        {
          'detector': 'compression_detector',
          'type': 'COMPRESSION_ANOMALY',
          'frame_start': 30,
          'frame_end': 40,
          'timestamp_start': 1.2,
          'timestamp_end': 1.6,
          'duration': 0.4,
          'score': 0.75,
          'confidence': 'MEDIUM',
          'signals': {'double_compression_periodic': true},
          'evidence': 'FFT periodicity detected in GOP structure',
        },
        {
          'detector': 'metadata_forensics',
          'type': 'METADATA_INCONSISTENCY',
          'frame_start': 0,
          'frame_end': 0,
          'timestamp_start': 0.0,
          'timestamp_end': 0.0,
          'duration': 0.0,
          'score': 0.65,
          'confidence': 'MEDIUM',
          'signals': {'fps_delta': 1.5},
          'evidence': 'Nominal vs calculated FPS mismatch',
        },
        {
          'detector': 'audio_sync_detector',
          'type': 'AUDIO_SYNC_ANOMALY',
          'frame_start': 50,
          'frame_end': 55,
          'timestamp_start': 2.0,
          'timestamp_end': 2.2,
          'duration': 0.2,
          'score': 0.70,
          'confidence': 'MEDIUM',
          'signals': {'energy_spike': true},
          'evidence': 'Sharp audio energy cut without video transition',
        },
        {
          'detector': 'deepfake_detector',
          'type': 'DEEPFAKE_FACE_CANDIDATE',
          'frame_start': 60,
          'frame_end': 70,
          'timestamp_start': 2.4,
          'timestamp_end': 2.8,
          'duration': 0.4,
          'score': 0.85,
          'confidence': 'HIGH',
          'signals': {'boundary_variance': 0.35},
          'evidence': 'Facial boundary blending artifacts detected',
        },
      ];

      final anomalies = anomaliesJson.map((j) => Anomaly.fromJson(j)).toList();

      expect(anomalies[0].isObjectManipulation, isTrue);
      expect(anomalies[0].displayTitle, 'Object Manipulation Candidate');

      expect(anomalies[1].isCompressionAnomaly, isTrue);
      expect(anomalies[1].displayTitle, 'Compression Forensics Anomaly');

      expect(anomalies[2].isMetadataAnomaly, isTrue);
      expect(anomalies[2].displayTitle, 'Metadata Forensic Discrepancy');

      expect(anomalies[3].isAudioSyncAnomaly, isTrue);
      expect(anomalies[3].displayTitle, 'Audio/Video Synchronization Anomaly');

      expect(anomalies[4].isDeepfake, isTrue);
      expect(anomalies[4].displayTitle, 'Deepfake Face Candidate');

      // Test ForensicSummary with extended anomaly counters
      final summary = ForensicSummary.fromJson({}, anomalies: anomalies);
      expect(summary.objectManipulationCandidates, 1);
      expect(summary.compressionAnomalies, 1);
      expect(summary.metadataInconsistencies, 1);
      expect(summary.audioSyncAnomalies, 1);
      expect(summary.deepfakeFaceCandidates, 1);

      // Verify serialization round-trip
      final summaryJson = summary.toJson();
      final deserialized = ForensicSummary.fromJson(summaryJson);
      expect(deserialized.objectManipulationCandidates, 1);
      expect(deserialized.compressionAnomalies, 1);
      expect(deserialized.metadataInconsistencies, 1);
      expect(deserialized.audioSyncAnomalies, 1);
      expect(deserialized.deepfakeFaceCandidates, 1);
    });
  });
}
