import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/google_logo.dart';
import '../controllers/auth_controller.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    const Color(0xFF161224),
                    AppColors.darkSurface,
                  ]
                : [
                    AppColors.lightBackground,
                    const Color(0xFFF0EDFF),
                    AppColors.lightSurface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Logo Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accentGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(90),
                          blurRadius: 20,
                          spreadRadius: 3,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // App Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.accentGradientEnd],
                    ).createShader(bounds),
                    child: const Text(
                      'MeetX',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Obx(
                    () => Text(
                      controller.isSignUp.value
                          ? 'Create your account to get started'
                          : 'Welcome back! Log in to continue',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Glassmorphic Form Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 80 : 15),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: controller.formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tab Switcher (Sign In / Sign Up)
                          Obx(
                            () => Container(
                              height: 44,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (controller.isSignUp.value) {
                                          controller.toggleAuthMode();
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: !controller.isSignUp.value
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: !controller.isSignUp.value
                                                ? Colors.white
                                                : (isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!controller.isSignUp.value) {
                                          controller.toggleAuthMode();
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: controller.isSignUp.value
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: controller.isSignUp.value
                                                ? Colors.white
                                                : (isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Animated Username Field (Visible only in Sign Up mode)
                          Obx(
                            () => AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: controller.isSignUp.value
                                  ? Column(
                                      children: [
                                        TextFormField(
                                          controller: controller.usernameController,
                                          focusNode: controller.usernameFocusNode,
                                          keyboardType: TextInputType.text,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            labelText: 'Username',
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (controller.isSignUp.value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Please enter a username';
                                              }
                                              if (value.trim().length < 3) {
                                                return 'Username must be at least 3 characters';
                                              }
                                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                                                return 'Only letters, numbers & underscores allowed';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),

                          // Email Input Field
                          TextFormField(
                            controller: controller.emailController,
                            focusNode: controller.emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Enter a valid email (e.g. name@domain.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password Input Field
                          Obx(
                            () => TextFormField(
                              controller: controller.passwordController,
                              focusNode: controller.passwordFocusNode,
                              obscureText: !controller.isPasswordVisible.value,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordVisible.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: controller.togglePasswordVisibility,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Forgot Password Link (Sign In mode only)
                          Obx(
                            () => !controller.isSignUp.value
                                ? Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        controller.sendForgotPassword(controller.emailController.text);
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 14),

                          // Submit Button (Sign In / Sign Up)
                          Obx(
                            () => SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        controller.isSignUp.value ? 'Create Account' : 'Sign In',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider Line
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.withAlpha(80))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.withAlpha(80))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Continue with Google Button (With Official 4-Color Google Logo)
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isDark ? AppColors.textSecondaryDark.withAlpha(80) : Colors.grey.shade300,
                                ),
                              ),
                              icon: const GoogleLogo(size: 20),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
