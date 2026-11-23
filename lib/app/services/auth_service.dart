import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../routes/app_pages.dart';

class AuthService extends GetxService with WidgetsBindingObserver {
  final AuthRepository _authRepository = AuthRepository();

  /// Reactive observable holding the current logged-in user profile
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  /// Convenient getter to check if user is logged in
  bool get isAuthenticated => currentUser.value != null;

  StreamSubscription<AuthState>? _authStateSubscription;

  Future<AuthService> init() async {
    WidgetsBinding.instance.addObserver(this);

    // 1. Initial check on app startup
    await _loadInitialUser();

    // 2. Listen to real-time Supabase Auth state changes (login, logout, session refresh)
    _listenToAuthStateChanges();

    // 3. Mark user online
    updateOnlineStatus(true);

    return this;
  }

  /// Update online/offline presence status in database
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _authRepository.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', uid);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      updateOnlineStatus(false);
    }
  }

  /// Load user profile if a valid session exists on app launch
  Future<void> _loadInitialUser() async {
    if (_authRepository.isAuthenticated) {
      final profile = await _authRepository.getCurrentProfile();
      currentUser.value = profile;
    } else {
      currentUser.value = null;
    }
  }

  /// Listen to Supabase Auth state changes dynamically
  void _listenToAuthStateChanges() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        final profile = await _authRepository.getCurrentProfile();
        currentUser.value = profile;
        updateOnlineStatus(true);
        if (Get.currentRoute != Routes.HOME) {
          Get.offAllNamed(Routes.HOME);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        updateOnlineStatus(false);
        currentUser.value = null;
        Get.offAllNamed(Routes.AUTH);
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        final profile = await _authRepository.getCurrentProfile();
        currentUser.value = profile;
      }
    });
  }

  /// Refresh the current user's profile from database
  Future<void> refreshUserProfile() async {
    final profile = await _authRepository.getCurrentProfile();
    currentUser.value = profile;
  }

  @override
  void onClose() {
    updateOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();
    super.onClose();
  }
}
