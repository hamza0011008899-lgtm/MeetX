import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../routes/app_pages.dart';

class UserSearchController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();

  final searchInputController = TextEditingController();
  final RxList<UserModel> searchResults = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    loadUsers('');
  }

  /// Perform live search or fetch all registered users
  void loadUsers(String query) async {
    isLoading.value = true;
    try {
      final users = await _chatRepository.searchUsers(query.trim());
      searchResults.assignAll(users);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Perform live search with debounce
  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadUsers(query);
    });
  }

  /// Start a 1-on-1 chat with selected user
  Future<void> startChatWithUser(UserModel targetUser) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
        barrierDismissible: false,
      );

      final chatId = await _chatRepository.getOrCreateSingleChat(targetUser.id);
      Get.back(); // Dismiss loading dialog

      // Open Chat Screen with target user arguments
      Get.toNamed(
        Routes.CHAT,
        arguments: {
          'chatId': chatId,
          'targetUser': targetUser,
        },
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Could not open conversation. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchInputController.dispose();
    super.onClose();
  }
}
