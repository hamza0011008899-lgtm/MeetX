import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../services/auth_service.dart';

class ChatController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final AuthService _authService = Get.find<AuthService>();

  final messageInputController = TextEditingController();
  final scrollController = ScrollController();

  late final String chatId;
  late final UserModel? targetUser;

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxBool isPartnerTyping = false.obs;

  RealtimeChannel? _realtimeChannel;
  Timer? _typingTimer;
  Timer? _broadcastDebounce;

  String get currentUserId => _authService.currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    chatId = args['chatId'] as String? ?? '';
    targetUser = args['targetUser'] as UserModel?;

    if (chatId.isNotEmpty) {
      _loadChatHistory();
      _subscribeToRealtime();
    }
  }

  /// Load initial message history for this chat room
  Future<void> _loadChatHistory() async {
    isLoading.value = true;
    try {
      final history = await _chatRepository.getChatMessages(chatId);
      messages.assignAll(history);
      await _chatRepository.markMessagesAsRead(chatId);
      _scrollToBottom();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load message history.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Subscribe to live WebSocket messages & typing indicators for this room
  void _subscribeToRealtime() {
    _realtimeChannel = _chatRepository.subscribeToMessages(chatId, (newMessage) {
      // Avoid duplicate messages if already added
      if (!messages.any((m) => m.id == newMessage.id)) {
        messages.add(newMessage);
        _scrollToBottom();
        if (newMessage.senderId != currentUserId) {
          _chatRepository.markMessagesAsRead(chatId);
        }
      }
    });

    // Listen to real-time typing broadcasts
    _realtimeChannel?.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final senderId = payload['sender_id'] as String?;
        if (senderId != currentUserId) {
          isPartnerTyping.value = true;
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 2), () {
            isPartnerTyping.value = false;
          });
        }
      },
    );
  }

  /// Broadcast typing status to partner
  void onTextChanged(String text) {
    if (_broadcastDebounce?.isActive ?? false) return;
    _broadcastDebounce = Timer(const Duration(milliseconds: 800), () {});

    _realtimeChannel?.sendBroadcastEvent(
      event: 'typing',
      payload: {'sender_id': currentUserId},
    );
  }

  /// Send a text message
  Future<void> sendMessage() async {
    final text = messageInputController.text.trim();
    if (text.isEmpty) return;

    messageInputController.clear();
    isSending.value = true;

    try {
      final sentMessage = await _chatRepository.sendMessage(
        chatId: chatId,
        content: text,
      );

      if (!messages.any((m) => m.id == sentMessage.id)) {
        messages.add(sentMessage);
        _scrollToBottom();
      }
    } catch (e) {
      Get.snackbar(
        'Failed to Send',
        'Could not send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Copy message text to clipboard
  void copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied 📋',
      'Message copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Delete message by ID
  Future<void> deleteMessage(MessageModel message) async {
    try {
      await _chatRepository.deleteMessage(message.id);
      messages.removeWhere((m) => m.id == message.id);
      Get.snackbar(
        'Deleted 🗑️',
        'Message deleted',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete message.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    _broadcastDebounce?.cancel();
    _realtimeChannel?.unsubscribe();
    messageInputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
