import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidforensic/features/results/models/forensic_results.dart';
import 'package:vidforensic/features/results/models/ai_forensic_result.dart';
import 'package:vidforensic/features/results/models/anomaly.dart';
import 'package:vidforensic/features/results/providers/results_provider.dart';
import 'package:vidforensic/features/results/presentation/results_dashboard_screen.dart';

void main() {
  testWidgets('ResultsDashboardScreen renders processing state with stage steps', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resultsProvider.overrideWith((ref) {
            final notifier = ResultsNotifier(ref);
            notifier.state = ResultsState(
              jobId: 'job_proc_123',
              isLoading: true,
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: ResultsDashboardScreen(jobId: 'job_proc_123'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Analyzing Video Sequence...'), findsOneWidget);
    expect(find.text('Job ID: job_proc_123'), findsOneWidget);
    expect(find.text('Uploading & Validating'), findsOneWidget);
    expect(find.text('Processing Multi-Detector Pipeline'), findsOneWidget);
  });

  testWidgets('ResultsDashboardScreen renders failed state with sanitized error message', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resultsProvider.overrideWith((ref) {
            final notifier = ResultsNotifier(ref);
            notifier.state = ResultsState(
              jobId: 'job_fail_123',
              isLoading: false,
              error: 'Invalid video container format or unsupported codec.',
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: ResultsDashboardScreen(jobId: 'job_fail_123'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Forensic Analysis Failed'), findsOneWidget);
    expect(find.text('Job ID: job_fail_123'), findsOneWidget);
    expect(find.text('Invalid video container format or unsupported codec.'), findsOneWidget);
    expect(find.text('Retry Analysis Fetch'), findsOneWidget);
  });

  testWidgets('ResultsDashboardScreen renders simplified summary and PDF report tab', (WidgetTester tester) async {
    final mockResults = ForensicResults(
      jobId: 'job_comp_123',
      videoName: 'ai_realistic_test.mp4',
      status: 'completed',
      createdAt: '2026-09-26T18:00:00Z',
      metadata: VideoMetadata.fromJson({
        'width': 1920,
        'height': 1080,
        'fps': 24.0,
        'total_frames': 240,
        'duration': 10.0,
      }),
      summary: ForensicSummary(
        totalAnomalies: 5,
        freezeFrames: 0,
        duplicateFrames: 0,
        missingFrames: 1,
        corruptedFrames: 0,
        visualDiscontinuities: 1,
        visualAnomalies: 0,
        missingPtsGaps: 0,
        modificationCandidates: 2,
        sceneChanges: 0,
        aiContentCandidates: 2,
      ),
      anomalies: [
        Anomaly(
          detector: 'ai_detector',
          type: 'AI_CONTENT_CANDIDATE',
          frameStart: 2,
          frameEnd: 120,
          timestampStart: 0.08,
          timestampEnd: 5.0,
          duration: 4.92,
          score: 0.75,
          confidence: 'HIGH',
          evidence: 'FFT spectral grid artifacts detected',
        ),
      ],
      aiDetection: AiForensicResult(
        status: 'analyzed',
        score: 0.75,
        confidence: 'HIGH',
        classification: 'LIKELY_AI_GENERATED',
        assessmentLabel: 'LIKELY_AI_GENERATED',
        candidateCount: 2,
        segments: [],
        signals: {'fft_anomaly': 0.75},
        limitations: ['High compression artifacts may influence statistical metrics.'],
      ),
    );

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resultsProvider.overrideWith((ref) {
            final notifier = ResultsNotifier(ref);
            notifier.state = ResultsState(
              jobId: 'job_comp_123',
              isLoading: false,
              results: mockResults,
              evidenceItems: mockResults.anomalies,
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: ResultsDashboardScreen(jobId: 'job_comp_123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify simplified result summary card
    expect(find.text('FINAL RESULT'), findsOneWidget);
    expect(find.text('🔴 AI GENERATED'), findsOneWidget);
    expect(find.text('VIEW PDF REPORT'), findsOneWidget);

    // Switch to Tab 2: PDF Report
    final pdfTab = find.text('PDF Report');
    await tester.ensureVisible(pdfTab);
    await tester.tap(pdfTab);
    await tester.pumpAndSettle();

    expect(find.text('OPEN PDF REPORT'), findsOneWidget);
    expect(find.text('DOWNLOAD PDF'), findsOneWidget);
    expect(find.text('SHARE PDF'), findsOneWidget);
  });
}
