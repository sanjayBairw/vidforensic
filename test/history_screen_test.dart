import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidforensic/core/network/api_provider.dart';
import 'package:vidforensic/features/history/models/history_item.dart';

import 'package:vidforensic/features/history/providers/history_provider.dart';
import 'package:vidforensic/features/history/presentation/history_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HistoryScreen renders empty state when no items exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Analysis History'), findsOneWidget);
    expect(find.text('No forensic analyses yet.'), findsOneWidget);
    expect(find.text('Upload a video to start your first analysis.'), findsOneWidget);
    expect(find.text('ANALYZE VIDEO'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders list of jobs with forensic status pills', (WidgetTester tester) async {
    final mockItem1 = HistoryItem(
      jobId: 'job_001',
      filename: 'ai_video.mp4',
      date: '2026-09-26T18:00:00Z',
      status: 'COMPLETED',
      anomalyCount: 5,
      aiCandidates: 2,
      modificationCandidates: 1,
    );

    final mockItem2 = HistoryItem(
      jobId: 'job_002',
      filename: 'normal_video.mp4',
      date: '2026-09-26T19:00:00Z',
      status: 'PROCESSING',
      anomalyCount: 0,
      aiCandidates: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyProvider.overrideWith((ref) {
            final apiClient = ref.watch(apiClientProvider);
            final notifier = HistoryNotifier(apiClient);
            notifier.state = [mockItem1, mockItem2];
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ai_video.mp4'), findsOneWidget);

    expect(find.text('normal_video.mp4'), findsOneWidget);
    expect(find.text('AI CONTENT CANDIDATE'), findsOneWidget);
    expect(find.text('ANALYSIS IN PROGRESS'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('PROCESSING'), findsOneWidget);
  });

  testWidgets('Delete icon opens confirmation dialog', (WidgetTester tester) async {
    final mockItem = HistoryItem(
      jobId: 'job_delete_123',
      filename: 'sample.mp4',
      date: '2026-09-26T18:00:00Z',
      status: 'COMPLETED',
      anomalyCount: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyProvider.overrideWith((ref) {
            final apiClient = ref.watch(apiClientProvider);
            final notifier = HistoryNotifier(apiClient);
            notifier.state = [mockItem];
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap delete button on the card
    final deleteIconButton = find.byIcon(Icons.delete_outline).first;
    await tester.tap(deleteIconButton);
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Delete Job?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
