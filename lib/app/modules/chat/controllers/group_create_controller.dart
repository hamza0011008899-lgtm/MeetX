import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../routes/app_pages.dart';

class GroupCreateController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();

  final groupNameController = TextEditingController();
  final searchController = TextEditingController();

  final RxList<UserModel> availableUsers = <UserModel>[].obs;
  final RxSet<String> selectedUserIds = <String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    isLoading.value = true;
    try {
      final users = await _chatRepository.searchUsers('a');
      availableUsers.assignAll(users);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _loadAvailableUsers();
      return;
    }
    isLoading.value = true;
    try {
      final users = await _chatRepository.searchUsers(query.trim());
      availableUsers.assignAll(users);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void toggleUserSelection(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
  }

  Future<void> createGroup() async {
    final name = groupNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Group Name Required',
        'Please enter a name for your group.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedUserIds.isEmpty) {
      Get.snackbar(
        'Members Required',
        'Please select at least 1 member for the group.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isCreating.value = true;
    try {
      final chatId = await _chatRepository.createGroupChat(
        name,
        selectedUserIds.toList(),
      );

      Get.offNamed(
        Routes.CHAT,
        arguments: {
          'chatId': chatId,
          'targetUser': null,
          'chatTitle': name,
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create group chat.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCreating.value = false;
    }
  }

  @override
  void onClose() {
    groupNameController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
