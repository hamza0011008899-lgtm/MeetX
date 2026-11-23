import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/user_search_controller.dart';

class UserSearchView extends StatelessWidget {
  const UserSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserSearchController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: controller.searchInputController,
          autofocus: true,
          onChanged: controller.onSearchChanged,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search by username or name...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 15,
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              controller.searchInputController.clear();
              controller.loadUsers('');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 64,
                  color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(100),
                ),
                const SizedBox(height: 12),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    controller.debugInfo.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: AppColors.primary.withAlpha(20),
              child: Text(
                controller.debugInfo.value,
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.searchResults.length,
                itemBuilder: (context, index) {
                  final user = controller.searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withAlpha(40),
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Text(
                              (user.displayName ?? user.username)[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.displayName ?? user.username,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    onTap: () => controller.startChatWithUser(user),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
