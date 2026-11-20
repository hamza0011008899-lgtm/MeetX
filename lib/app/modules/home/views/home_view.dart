import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/auth_service.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final authRepository = AuthRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeetX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              Get.defaultDialog(
                title: 'Logout',
                middleText: 'Are you sure you want to log out of MeetX?',
                textConfirm: 'Logout',
                textCancel: 'Cancel',
                confirmTextColor: Colors.white,
                buttonColor: Colors.redAccent,
                onConfirm: () async {
                  Get.back();
                  await authRepository.signOut();
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Obx(
          () {
            final user = authService.currentUser.value;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Color(0xFF6C5CE7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to MeetX',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user != null ? 'Logged in as: ${user.email}' : 'Logged in',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
