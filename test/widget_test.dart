import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidforensic/main.dart';
import 'package:vidforensic/core/network/api_provider.dart';
import 'package:vidforensic/core/network/api_client.dart';

class MockApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {'status': 'healthy'};
  }
}

void main() {
  testWidgets('VidForensic app renders home screen with title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
        ],
        child: const VidForensicApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VidForensic'), findsWidgets);
    expect(find.text('Video Forensic Analyzer'), findsOneWidget);
    expect(find.text('Analyze New Video'), findsOneWidget);
    expect(find.text('Analysis History'), findsOneWidget);
  });
}
