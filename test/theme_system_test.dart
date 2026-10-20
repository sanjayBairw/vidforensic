import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidforensic/core/theme/theme_provider.dart';
import 'package:vidforensic/core/theme/app_colors.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier Unit Tests', () {
    test('Defaults to Light Mode for first-time users when prefs are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).initialized;
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.light);
    });

    test('Loads dark mode when saved in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).initialized;
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.dark);
    });

    test('Loads system mode when saved in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'system'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).initialized;
      final mode = container.read(themeModeProvider);
      expect(mode, ThemeMode.system);
    });

    test('Switching to dark mode updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).initialized;
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');
    });

    test('Switching to system mode updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).initialized;
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'system');
    });

    test('Switching back to light mode updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).initialized;
      await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');
    });
  });

  group('Theme System Widget & UI Tests', () {
    testWidgets('App renders initially in Light Mode by default', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(MockApiClient()),
          ],
          child: const VidForensicApp(),
        ),
      );

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);
      expect(materialApp.theme?.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(materialApp.darkTheme?.scaffoldBackgroundColor, AppColors.darkBackground);
    });

    testWidgets('Tapping theme toggle icon in AppBar opens theme selection dialog', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(MockApiClient()),
          ],
          child: const VidForensicApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find theme toggle icon button via tooltip
      final themeIcon = find.byTooltip('Appearance & Theme');
      expect(themeIcon, findsOneWidget);

      await tester.tap(themeIcon);
      await tester.pumpAndSettle();

      // Verify theme selection modal appears with Light, Dark, System
      expect(find.text('App Appearance'), findsOneWidget);
      expect(find.text('Light Mode (Default)'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);

      // Tap Dark Mode option
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      // Verify MaterialApp updated to dark mode
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });
  });
}
