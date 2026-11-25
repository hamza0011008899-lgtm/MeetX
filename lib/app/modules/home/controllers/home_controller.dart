import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../services/auth_service.dart';

class HomeController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ChatModel> chatList = <ChatModel>[].obs;
  final RxList<MessageModel> callHistory = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;

  String get currentUserId => _authService.currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    loadUserChats();
    loadCallHistory();
  }

  @override
  void onReady() {
    super.onReady();
    loadUserChats();
    loadCallHistory();
  }

  /// Load user active conversation list
  Future<void> loadUserChats() async {
    isLoading.value = true;
    try {
      final chats = await _chatRepository.getUserChats();
      debugPrint('DEBUG loadUserChats found ${chats.length} active chats');
      chatList.assignAll(chats);
    } catch (e) {
      debugPrint('DEBUG loadUserChats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load recent call history for Calls tab
  Future<void> loadCallHistory() async {
    try {
      final calls = await _chatRepository.getCallHistory();
      callHistory.assignAll(calls);
    } catch (e) {
      debugPrint('DEBUG loadCallHistory error: $e');
    }
  }
}
