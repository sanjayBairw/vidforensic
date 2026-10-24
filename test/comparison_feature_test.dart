import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidforensic/features/comparison/models/comparison_models.dart';
import 'package:vidforensic/features/comparison/providers/comparison_provider.dart';
import 'package:vidforensic/features/comparison/presentation/widgets/comparison_summary_card.dart';
import 'package:vidforensic/features/comparison/presentation/widgets/metadata_table_widget.dart';
import 'package:vidforensic/features/comparison/presentation/widgets/timeline_intervals_widget.dart';
import 'package:vidforensic/features/home/presentation/home_screen.dart';
import 'package:vidforensic/core/network/api_client.dart';
import 'package:vidforensic/core/network/api_provider.dart';

void main() {
  group('Video Comparison Models JSON Parsing Tests', () {
    test('VideoMetadata parsing', () {
      final json = {
        'label': 'Reference Video (A)',
        'filename': 'normal_test.mp4',
        'file_size': 166548,
        'sha256': 'abcdef1234567890',
        'container': '.mp4',
        'codec': 'H264',
        'width': 1280,
        'height': 720,
        'aspect_ratio': '16:9',
        'fps': 30.0,
        'frame_count': 300,
        'duration': 10.0,
        'bitrate': '1500 kbps',
        'audio_present': true,
      };

      final meta = VideoMetadata.fromJson(json);
      expect(meta.label, 'Reference Video (A)');
      expect(meta.filename, 'normal_test.mp4');
      expect(meta.fileSize, 166548);
      expect(meta.width, 1280);
      expect(meta.height, 720);
      expect(meta.aspectRatio, '16:9');
      expect(meta.fps, 30.0);
      expect(meta.duration, 10.0);
      expect(meta.audioPresent, isTrue);
    });

    test('MetadataComparison and Discrepancies parsing', () {
      final json = {
        'resolution_match': false,
        'fps_match': true,
        'duration_match': false,
        'duration_delta': -2.5,
        'size_ratio': 0.75,
        'total_discrepancies': 2,
        'discrepancies': [
          {
            'category': 'Resolution Mismatch',
            'severity': 'MODERATE',
            'detail': 'Reference is 1920x1080, Suspected is 1280x720.',
          },
          {
            'category': 'Duration Discrepancy',
            'severity': 'SIGNIFICANT',
            'detail': 'Suspected video is 2.5s shorter.',
          }
        ],
      };

      final comp = MetadataComparison.fromJson(json);
      expect(comp.resolutionMatch, isFalse);
      expect(comp.fpsMatch, isTrue);
      expect(comp.durationMatch, isFalse);
      expect(comp.durationDelta, -2.5);
      expect(comp.sizeRatio, 0.75);
      expect(comp.totalDiscrepancies, 2);
      expect(comp.discrepancies.length, 2);
      expect(comp.discrepancies.first.category, 'Resolution Mismatch');
      expect(comp.discrepancies.last.severity, 'SIGNIFICANT');
    });

    test('SuspiciousInterval parsing', () {
      final json = {
        'interval_id': 'INT_01',
        'interval_index': 1,
        'start_time_a': 2.50,
        'end_time_a': 4.00,
        'start_time_b': 2.50,
        'end_time_b': 4.00,
        'duration': 1.50,
        'sample_count': 3,
        'min_ssim': 0.54,
        'max_difference': 0.42,
        'average_mae': 0.22,
        'average_phash_distance': 0.18,
        'severity': 'SIGNIFICANT',
        'explanation': 'Major structural difference detected; content alteration suspected.',
        'peak_timestamp_a': 3.00,
        'peak_timestamp_b': 3.00,
        'evidence_files': {
          'ref_frame': 'evidence_ref_01.jpg',
          'susp_frame': 'evidence_susp_01.jpg',
          'diff_heatmap': 'evidence_diff_01.jpg',
          'composite_plate': 'evidence_plate_01.jpg',
        },
      };

      final it = SuspiciousInterval.fromJson(json);
      expect(it.intervalId, 'INT_01');
      expect(it.intervalIndex, 1);
      expect(it.startTimeA, 2.50);
      expect(it.endTimeA, 4.00);
      expect(it.duration, 1.50);
      expect(it.minSsim, 0.54);
      expect(it.maxDifference, 0.42);
      expect(it.severity, 'SIGNIFICANT');
      expect(it.evidenceFiles['composite_plate'], 'evidence_plate_01.jpg');
    });

    test('Full ComparisonResults parsing', () {
      final fullJson = {
        'comparison_id': 'comp_test_789',
        'generated_at': '2026-10-20T00:00:00Z',
        'configuration': {
          'time_offset': 0.5,
          'sample_interval': 0.5,
        },
        'summary': {
          'overall_similarity_percentage': 88.5,
          'verdict': 'LOCALIZED_ANOMALIES_DETECTED',
          'verdict_label': 'LOCALIZED DISCREPANCIES DETECTED - REVIEW RECOMMENDED',
          'severity': 'MEDIUM',
          'total_samples_analyzed': 20,
          'total_suspicious_intervals': 1,
          'overlap_duration': 9.5,
          'average_ssim': 0.885,
          'average_mae': 0.045,
          'average_phash_distance': 0.05,
          'average_histogram_similarity': 0.94,
        },
        'video_a': {
          'label': 'Reference',
          'filename': 'ref.mp4',
          'file_size': 100000,
          'sha256': 'hash_a',
          'container': '.mp4',
          'codec': 'H264',
          'width': 1920,
          'height': 1080,
          'aspect_ratio': '16:9',
          'fps': 30.0,
          'frame_count': 300,
          'duration': 10.0,
          'bitrate': '2000 kbps',
          'audio_present': true,
        },
        'video_b': {
          'label': 'Suspected',
          'filename': 'susp.mp4',
          'file_size': 90000,
          'sha256': 'hash_b',
          'container': '.mp4',
          'codec': 'H264',
          'width': 1920,
          'height': 1080,
          'aspect_ratio': '16:9',
          'fps': 30.0,
          'frame_count': 300,
          'duration': 10.0,
          'bitrate': '1800 kbps',
          'audio_present': true,
        },
        'metadata_comparison': {
          'resolution_match': true,
          'fps_match': true,
          'duration_match': true,
          'duration_delta': 0.0,
          'size_ratio': 0.9,
          'total_discrepancies': 0,
          'discrepancies': [],
        },
        'unmatched_intervals': [],
        'suspicious_intervals': [
          {
            'interval_id': 'INT_01',
            'interval_index': 1,
            'start_time_a': 1.0,
            'end_time_a': 2.0,
            'start_time_b': 1.5,
            'end_time_b': 2.5,
            'duration': 1.0,
            'sample_count': 2,
            'min_ssim': 0.72,
            'max_difference': 0.28,
            'average_mae': 0.08,
            'average_phash_distance': 0.06,
            'severity': 'MODERATE',
            'explanation': 'Localized discrepancy observed.',
            'peak_timestamp_a': 1.5,
            'peak_timestamp_b': 2.0,
            'evidence_files': {},
          }
        ],
        'timeline_samples': [
          {
            'sample_idx': 0,
            'timestamp_a': 0.0,
            'timestamp_b': 0.5,
            'ssim': 0.98,
            'mae': 0.01,
            'phash_distance': 0.0,
            'hist_similarity': 0.99,
            'difference_score': 0.02,
            'is_anomalous': false,
          }
        ],
        'detector_correlations': {'scene_cuts_detected': 0},
        'limitations': ['Test limitation note.'],
      };

      final results = ComparisonResults.fromJson(fullJson);
      expect(results.comparisonId, 'comp_test_789');
      expect(results.timeOffset, 0.5);
      expect(results.summary.overallSimilarityPercentage, 88.5);
      expect(results.summary.verdict, 'LOCALIZED_ANOMALIES_DETECTED');
      expect(results.suspiciousIntervals.length, 1);
      expect(results.timelineSamples.length, 1);
      expect(results.limitations.first, 'Test limitation note.');
    });

    test('Full ComparisonResults with correlated forgery detectors parsing', () {
      final jsonWithForgeryCorrelations = {
        'comparison_id': 'comp_forgery_001',
        'generated_at': '2026-10-24T20:00:00Z',
        'configuration': {'time_offset': 0.0, 'sample_interval': 0.5},
        'summary': {
          'overall_similarity_percentage': 72.0,
          'verdict': 'MAJOR_DIVERGENCE_DETECTED',
          'verdict_label': 'SIGNIFICANT FORENSIC DIVERGENCE / CONTENT MODIFICATION',
          'severity': 'HIGH',
          'total_samples_analyzed': 30,
          'total_suspicious_intervals': 2,
          'overlap_duration': 10.0,
          'average_ssim': 0.72,
          'average_mae': 0.12,
          'average_phash_distance': 0.15,
          'average_histogram_similarity': 0.88,
        },
        'video_a': {
          'label': 'Reference Video (A)',
          'filename': 'ref.mp4',
          'file_size': 500000,
          'sha256': 'hash_a',
          'container': '.mp4',
          'codec': 'H264',
          'width': 1280,
          'height': 720,
          'aspect_ratio': '16:9',
          'fps': 25.0,
          'frame_count': 250,
          'duration': 10.0,
          'bitrate': '2000 kbps',
          'audio_present': false,
        },
        'video_b': {
          'label': 'Suspected Video (B)',
          'filename': 'susp.mp4',
          'file_size': 520000,
          'sha256': 'hash_b',
          'container': '.mp4',
          'codec': 'H264',
          'width': 1280,
          'height': 720,
          'aspect_ratio': '16:9',
          'fps': 25.0,
          'frame_count': 250,
          'duration': 10.0,
          'bitrate': '2100 kbps',
          'audio_present': false,
        },
        'metadata_comparison': {
          'resolution_match': true,
          'fps_match': true,
          'duration_match': true,
          'duration_delta': 0.0,
          'size_ratio': 1.04,
          'total_discrepancies': 0,
          'discrepancies': [],
        },
        'unmatched_intervals': [],
        'suspicious_intervals': [
          {
            'interval_id': 'INT_01',
            'interval_index': 1,
            'start_time_a': 3.0,
            'end_time_a': 4.5,
            'start_time_b': 3.0,
            'end_time_b': 4.5,
            'duration': 1.5,
            'sample_count': 3,
            'min_ssim': 0.45,
            'max_difference': 0.55,
            'average_mae': 0.28,
            'average_phash_distance': 0.32,
            'severity': 'SIGNIFICANT',
            'explanation': 'Content replacement detected in interval.',
            'peak_timestamp_a': 3.5,
            'peak_timestamp_b': 3.5,
            'evidence_files': {'composite_plate': 'evidence_plate_01.jpg'},
          }
        ],
        'timeline_samples': [],
        'detector_correlations': {
          'target': 'Suspected Video (B)',
          'source_video': 'video_b',
          'filename': 'susp.mp4',
          'scene_cuts_detected': 1,
          'splice_candidates_detected': 1,
          'copy_move_candidates_detected': 1,
          'copy_move_candidates': [
            {
              'frame': 45,
              'timestamp': 1.8,
              'match_count': 18,
              'confidence': 'MEDIUM',
              'source_video': 'video_b',
            }
          ],
          'splice_candidates': [
            {
              'frame_before': 75,
              'frame_after': 76,
              'timestamp': 3.0,
              'confidence': 'HIGH',
              'source_video': 'video_b',
            }
          ],
        },
        'limitations': ['Forensic analysis is probabilistic.'],
      };

      final parsed = ComparisonResults.fromJson(jsonWithForgeryCorrelations);
      expect(parsed.comparisonId, 'comp_forgery_001');
      expect(parsed.summary.severity, 'HIGH');
      expect(parsed.detectorCorrelations['source_video'], 'video_b');
      expect(parsed.detectorCorrelations['copy_move_candidates_detected'], 1);
      expect(parsed.detectorCorrelations['splice_candidates_detected'], 1);
      final cmList = parsed.detectorCorrelations['copy_move_candidates'] as List;
      expect(cmList.first['source_video'], 'video_b');
      final spList = parsed.detectorCorrelations['splice_candidates'] as List;
      expect(spList.first['source_video'], 'video_b');
    });
  });

  group('ComparisonState & Notifier Unit Tests', () {
    test('State initial values and copyWith', () {
      final state = ComparisonState();
      expect(state.status, 'initial');
      expect(state.isUploading, isFalse);
      expect(state.timeOffset, 0.0);
      expect(state.sampleInterval, 0.5);

      final updated = state.copyWith(
        timeOffset: 1.5,
        sampleInterval: 0.8,
        status: 'processing',
        progress: 0.45,
      );
      expect(updated.timeOffset, 1.5);
      expect(updated.sampleInterval, 0.8);
      expect(updated.status, 'processing');
      expect(updated.progress, 0.45);
    });

    test('Notifier time offset and interval settings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(comparisonProvider.notifier);
      expect(container.read(comparisonProvider).timeOffset, 0.0);

      notifier.setTimeOffset(1.2);
      expect(container.read(comparisonProvider).timeOffset, 1.2);

      notifier.setSampleInterval(0.3);
      expect(container.read(comparisonProvider).sampleInterval, 0.3);

      notifier.selectInterval(2);
      expect(container.read(comparisonProvider).selectedIntervalIndex, 2);

      notifier.reset();
      expect(container.read(comparisonProvider).status, 'initial');
      expect(container.read(comparisonProvider).timeOffset, 0.0);
    });
  });

  group('Comparison UI Widgets Tests', () {
    testWidgets('ComparisonSummaryCard renders metrics and verdict', (tester) async {
      final summary = ComparisonSummary(
        overallSimilarityPercentage: 94.2,
        verdict: 'LOCALIZED_ANOMALIES_DETECTED',
        verdictLabel: 'LOCALIZED DISCREPANCIES DETECTED',
        severity: 'MEDIUM',
        totalSamplesAnalyzed: 30,
        totalSuspiciousIntervals: 2,
        overlapDuration: 15.0,
        averageSsim: 0.942,
        averageMae: 0.024,
        averagePhashDistance: 0.038,
        averageHistogramSimilarity: 0.96,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSummaryCard(
              summary: summary,
              onDownloadReport: () {},
            ),
          ),
        ),
      );

      expect(find.text('LOCALIZED DISCREPANCIES DETECTED'), findsOneWidget);
      expect(find.text('94.2%'), findsOneWidget);
      expect(find.text('0.942'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
    });

    testWidgets('MetadataTableWidget renders metadata rows', (tester) async {
      final videoA = VideoMetadata(
        label: 'Reference Video (A)',
        filename: 'ref.mp4',
        fileSize: 1048576,
        sha256: 'sha256_ref',
        container: '.mp4',
        codec: 'H264',
        width: 1920,
        height: 1080,
        aspectRatio: '16:9',
        fps: 30.0,
        frameCount: 300,
        duration: 10.0,
        bitrate: '2000 kbps',
        audioPresent: true,
      );

      final videoB = VideoMetadata(
        label: 'Suspected Video (B)',
        filename: 'susp.mp4',
        fileSize: 524288,
        sha256: 'sha256_susp',
        container: '.mp4',
        codec: 'H264',
        width: 1280,
        height: 720,
        aspectRatio: '16:9',
        fps: 25.0,
        frameCount: 250,
        duration: 10.0,
        bitrate: '1200 kbps',
        audioPresent: true,
      );

      final metaComp = MetadataComparison(
        resolutionMatch: false,
        fpsMatch: false,
        durationMatch: true,
        durationDelta: 0.0,
        sizeRatio: 0.5,
        totalDiscrepancies: 2,
        discrepancies: [
          MetadataDiscrepancy(
            category: 'Resolution Mismatch',
            severity: 'MODERATE',
            detail: 'Reference is 1920x1080, Suspected is 1280x720.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetadataTableWidget(
                videoA: videoA,
                videoB: videoB,
                metadataComparison: metaComp,
              ),
            ),
          ),
        ),
      );

      expect(find.text('METADATA AUDIT & DISCREPANCY ANALYSIS'), findsOneWidget);
      expect(find.text('ref.mp4'), findsOneWidget);
      expect(find.text('susp.mp4'), findsOneWidget);
      expect(find.text('DIFFERENT'), findsOneWidget);
      expect(find.text('MISMATCH'), findsOneWidget);
    });

    testWidgets('TimelineIntervalsWidget renders timeline bar and intervals', (tester) async {
      final intervals = [
        SuspiciousInterval(
          intervalId: 'INT_01',
          intervalIndex: 1,
          startTimeA: 1.0,
          endTimeA: 3.0,
          startTimeB: 1.0,
          endTimeB: 3.0,
          duration: 2.0,
          sampleCount: 4,
          minSsim: 0.65,
          maxDifference: 0.35,
          averageMae: 0.12,
          averagePhashDistance: 0.08,
          severity: 'MODERATE',
          explanation: 'Localized alteration detected.',
          peakTimestampA: 2.0,
          peakTimestampB: 2.0,
          evidenceFiles: {},
        )
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineIntervalsWidget(
              totalDuration: 10.0,
              intervals: intervals,
              selectedIntervalIndex: 1,
              onSelectInterval: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('SYNCHRONIZED TIMELINE'), findsOneWidget);
      expect(find.text('1 Discrepancy Detected'), findsOneWidget);
    });

    testWidgets('HomeScreen contains Video Comparison button and navigates',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_MockApiClient()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Video Comparison button is present on Home Screen
      expect(find.text('Video Comparison Mode'), findsWidgets);
    });
  });
}

class _MockApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {'status': 'healthy', 'service': 'video-forensics-api'};
  }
}
