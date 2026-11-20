import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Text Controllers for input fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  // Focus Nodes to control keyboard focus dynamically
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final usernameFocusNode = FocusNode();

  // Form Key for validation
  final formKey = GlobalKey<FormState>();

  // Reactive UI states
  final RxBool isSignUp = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;

  /// Toggle between Sign In and Sign Up modes and switch focus
  void toggleAuthMode() {
    isSignUp.value = !isSignUp.value;
    formKey.currentState?.reset();

    // Auto-focus on appropriate field after mode switch animation
    Future.delayed(const Duration(milliseconds: 150), () {
      if (isSignUp.value) {
        usernameFocusNode.requestFocus();
      } else {
        emailFocusNode.requestFocus();
      }
    });
  }

  /// Toggle password field visibility (eye icon)
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Trigger Google OAuth Sign In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authRepository.signInWithGoogle();
    } on AuthException catch (e) {
      Get.snackbar(
        'Google Auth Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not initiate Google Sign-In. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Send Password Reset Email
  Future<void> sendForgotPassword(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address to reset password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _authRepository.resetPassword(trimmedEmail);
      Get.snackbar(
        'Reset Email Sent 📧',
        'Check your inbox for the password reset link.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on AuthException catch (e) {
      Get.snackbar(
        'Reset Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Execute Sign In or Sign Up based on current mode
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      if (isSignUp.value) {
        // Handle Registration
        final response = await _authRepository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          username: usernameController.text.trim(),
        );

        if (response.user != null) {
          // If session is null, email confirmation is required by Supabase
          if (response.session == null) {
            Get.defaultDialog(
              title: 'Verify Your Email 📧',
              titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              middleText: 'A verification link has been sent to ${emailController.text.trim()}.\n\nPlease check your inbox and confirm your email before signing in.',
              textConfirm: 'Got it!',
              confirmTextColor: Colors.white,
              buttonColor: const Color(0xFF6C5CE7),
              onConfirm: () {
                Get.back();
                toggleAuthMode();
              },
            );
          } else {
            Get.snackbar(
              'Success 🎉',
              'Account created successfully! Welcome to MeetX.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            Get.offAllNamed(Routes.HOME);
          }
        }
      } else {
        // Handle Login
        final response = await _authRepository.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (response.user != null) {
          Get.snackbar(
            'Welcome Back! 👋',
            'Successfully logged in.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.offAllNamed(Routes.HOME);
        }
      }
    } on AuthException catch (e) {
      Get.snackbar(
        'Authentication Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    usernameFocusNode.dispose();
    super.onClose();
  }
}
