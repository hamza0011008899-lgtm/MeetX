import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  /// Returns the currently authenticated Supabase Auth User
  User? get currentUser => _client.auth.currentUser;

  /// Check if a user is currently logged in
  bool get isAuthenticated => currentUser != null;

  /// Register a new user with email, password, and username
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName ?? username,
      },
    );
    return response;
  }

  /// Sign in an existing user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sign in using Google OAuth
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.meetx://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.meetx://reset-password',
    );
  }

  /// Sign out the current user session
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch the full profile of the currently logged-in user from database
  Future<UserModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return UserModel.fromJson(response, userEmail: user.email);
  }

  /// Fetch profile by user ID
  Future<UserModel?> getProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserModel.fromJson(response);
  }

  /// Update current user profile details
  Future<void> updateProfile({
    String? displayName,
    String? statusMessage,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) updates['display_name'] = displayName;
    if (statusMessage != null) updates['status_message'] = statusMessage;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('profiles').update(updates).eq('id', user.id);
  }
}
