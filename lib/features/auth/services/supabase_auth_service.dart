import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';

class SupabaseAuthService {
  final SupabaseClient? _client;

  SupabaseAuthService([SupabaseClient? client])
      : _client = client ?? _getSafeClient();

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  Session? get currentSession => _client?.auth.currentSession;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client != null) {
      return client.auth.onAuthStateChange;
    }
    return const Stream.empty();
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.trim().isNotEmpty
            ? {'full_name': fullName.trim()}
            : null,
      );
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out of Supabase: $e');
    }
  }

  Future<void> resetPassword({required String email, String? redirectTo}) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo ?? SupabaseConstants.resetPasswordRedirectUrl,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AuthResponse> signInAnonymously() async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    try {
      final response = await client.auth.signInAnonymously();
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> resendVerificationEmail({required String email}) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}
