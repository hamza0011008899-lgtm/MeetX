import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/chat_controller.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  void _showMessageOptions(BuildContext context, ChatController controller, dynamic message, bool isMe) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.primary),
              title: const Text('Copy Text'),
              onTap: () {
                Get.back();
                if (message.content != null) {
                  controller.copyMessage(message.content!);
                }
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Get.back();
                  controller.deleteMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withAlpha(40),
              backgroundImage: controller.targetUser?.avatarUrl != null
                  ? NetworkImage(controller.targetUser!.avatarUrl!)
                  : null,
              child: controller.targetUser?.avatarUrl == null
                  ? Text(
                      (controller.targetUser?.displayName ?? controller.targetUser?.username ?? 'C')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.targetUser?.displayName ?? controller.targetUser?.username ?? 'Chat',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(
                    () => Text(
                      controller.isPartnerTyping.value
                          ? 'typing...'
                          : (controller.targetUser?.isOnline == true ? 'Online' : 'Offline'),
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: controller.isPartnerTyping.value ? FontStyle.italic : FontStyle.normal,
                        color: controller.isPartnerTyping.value
                            ? AppColors.primary
                            : (controller.targetUser?.isOnline == true
                                ? AppColors.onlineGreen
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              Get.snackbar(
                'MeetX Call',
                'Peer-to-Peer Voice Calling will be activated in Phase 6!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              Get.snackbar(
                'MeetX Video',
                'Peer-to-Peer Video Calling will be activated in Phase 6!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages Conversation History
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (controller.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(100),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet. Say hi! 👋',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = message.senderId == controller.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => _showMessageOptions(context, controller, message, isMe),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkChatBubbleReceiver
                                    : AppColors.lightChatBubbleReceiver),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 30 : 8),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                message.content ?? '',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: isMe
                                      ? Colors.white
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    message.createdAt != null
                                        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                                        : '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white.withAlpha(180)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                      size: 14,
                                      color: message.isRead ? AppColors.tickBlue : Colors.white.withAlpha(180),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 10),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: controller.messageInputController,
                        onChanged: controller.onTextChanged,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: controller.sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
