import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidforensic/core/constants/supabase_constants.dart';
import 'package:vidforensic/features/auth/services/supabase_auth_service.dart';
import 'package:vidforensic/features/auth/providers/auth_provider.dart';
import 'package:vidforensic/features/auth/presentation/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Constants & Configuration Tests', () {
    test('SupabaseConstants contains user configured project URL and publishable API key', () {
      expect(SupabaseConstants.supabaseUrl, 'https://rsocwvpxvxgskdgpmice.supabase.co');
      expect(SupabaseConstants.supabaseAnonKey, 'sb_publishable_XgQEgU4jnJ_Z083O4QxmyQ_nggdAv6t');
    });

    test('SupabaseAuthService safely handles uninitialized client state', () {
      final service = SupabaseAuthService(null);
      expect(service.isAvailable, isFalse);
      expect(service.currentUser, isNull);
      expect(service.currentSession, isNull);
      expect(service.isAuthenticated, isFalse);
    });

    test('AuthStateModel handles copyWith and message clearing', () {
      const state = AuthStateModel(
        isLoading: false,
        errorMessage: 'Initial error',
        successMessage: 'Initial success',
      );

      final cleared = state.copyWith(clearError: true, clearSuccess: true);
      expect(cleared.errorMessage, isNull);
      expect(cleared.successMessage, isNull);
      expect(cleared.isLoading, isFalse);

      final loadingState = cleared.copyWith(isLoading: true);
      expect(loadingState.isLoading, isTrue);
    });
  });

  group('Supabase Login Screen UI Tests', () {
    testWidgets('LoginScreen renders header, form inputs, and Supabase project badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('Investigator Authentication'), findsOneWidget);
      expect(find.text('VidForensic Cloud'), findsOneWidget);
      expect(find.textContaining('rsocwvpxvxgskdgpmice'), findsOneWidget);

      // Check segment buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Check form fields in Sign In mode
      expect(find.text('Work / Official Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Resend confirmation'), findsOneWidget);
      expect(find.text('Instant Cloud Sign-In (No Email Verification)'), findsOneWidget);
      expect(find.text('Authenticate & Sign In'), findsOneWidget);
      expect(find.text('Return to Forensic Workstation'), findsOneWidget);
    });

    testWidgets('Tapping Create Account segment toggles registration fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially full name field is not visible
      expect(find.text('Investigator Full Name'), findsNothing);

      // Tap Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Full Name field should now be present
      expect(find.text('Investigator Full Name'), findsOneWidget);
      expect(find.text('Create Supabase Account'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);
    });

    testWidgets('Form validation flags empty email or password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to and tap submit with empty inputs
      final submitButton = find.text('Authenticate & Sign In');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Validation errors should be displayed
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}
