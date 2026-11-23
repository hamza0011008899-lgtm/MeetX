import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/group_create_controller.dart';

class GroupCreateView extends StatelessWidget {
  const GroupCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GroupCreateController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isCreating.value ? null : controller.createGroup,
              child: controller.isCreating.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Group Name Header Card
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    child: const Icon(Icons.group_add_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: controller.groupNameController,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Enter group name...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Member Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search members to add...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Members Selection List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.availableUsers.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: controller.availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = controller.availableUsers[index];
                    return Obx(() {
                      final isSelected = controller.selectedUserIds.contains(user.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => controller.toggleUserSelection(user.id),
                        activeColor: AppColors.primary,
                        secondary: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withAlpha(40),
                          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  (user.displayName ?? user.username)[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(user.displayName ?? user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('@${user.username}', style: const TextStyle(fontSize: 12)),
                      );
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
