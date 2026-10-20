import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

class AuthStateModel {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthStateModel({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAuthenticated => user != null;

  AuthStateModel copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUser = false,
  }) {
    return AuthStateModel(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthStateModel> {
  final SupabaseAuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthStateModel(user: _authService.currentUser)) {
    _authService.authStateChanges.listen((data) {
      if (mounted) {
        state = state.copyWith(
          user: data.session?.user,
          clearUser: data.session?.user == null,
        );
      }
    });
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final res = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        user: res.user,
        successMessage: 'Successfully signed in as ${res.user?.email}',
      );
      return true;
    } on AuthException catch (e) {
      String msg = e.message;
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        msg = 'Invalid login credentials.\n\nNotice: If you just created this account, your email may still be unconfirmed! Supabase requires confirming your email before first login.\n\nTip: You can disable "Confirm email" in your Supabase Dashboard -> Authentication -> Providers -> Email for instant logins.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected authentication error occurred: $e',
      );
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final res = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      final hasSession = res.session != null;
      if (hasSession) {
        state = state.copyWith(
          isLoading: false,
          user: res.user,
          successMessage: 'Account created and authenticated successfully!',
        );
      } else {
        // Email confirmation is required by Supabase: no session returned yet!
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          successMessage:
              'Account created! A verification link was sent to $email.\n\nPlease check your email to activate your account before signing in, or disable "Confirm email" in Supabase Dashboard -> Authentication -> Providers -> Email.',
        );
      }
      return true;
    } on AuthException catch (e) {
      String msg = e.message;
      if (e.message.toLowerCase().contains('rate limit')) {
        msg = 'Email rate limit exceeded.\n\nSupabase default SMTP only permits a few emails per hour. To log in immediately without waiting for confirmation emails, turn OFF "Confirm email" in Supabase Dashboard -> Authentication -> Providers -> Email.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected registration error occurred: $e',
      );
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final res = await _authService.signInAnonymously();
      state = state.copyWith(
        isLoading: false,
        user: res.user,
        successMessage: 'Authenticated as Cloud Guest Investigator.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected guest login error occurred: $e',
      );
      return false;
    }
  }

  Future<bool> resendConfirmationEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _authService.resendVerificationEmail(email: email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Confirmation email resent to $email. Please check your inbox or spam folder.',
      );
      return true;
    } on AuthException catch (e) {
      String msg = e.message;
      if (e.message.toLowerCase().contains('rate limit')) {
        msg = 'Email rate limit exceeded by Supabase. Please wait a few minutes or disable "Confirm email" in Supabase project dashboard.';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to resend confirmation email: $e',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      state = const AuthStateModel(
        successMessage: 'Successfully signed out.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error during sign out: $e',
      );
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _authService.resetPassword(email: email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset instructions sent to $email.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send password reset email: $e',
      );
      return false;
    }
  }
}

final authServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStateModel>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});
