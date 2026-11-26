import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';
import '../../../services/call_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/voice_note_player.dart';
import '../controllers/chat_controller.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  Color _getMemberColor(String senderId) {
    const colors = [
      Color(0xFFE84393),
      Color(0xFF00CEC9),
      Color(0xFFFF7675),
      Color(0xFF6C5CE7),
      Color(0xFF00B894),
      Color(0xFFFDCB6E),
      Color(0xFF0984E3),
      Color(0xFFE17055),
    ];
    final hash = senderId.hashCode.abs();
    return colors[hash % colors.length];
  }

  void _showAttachmentOptions(BuildContext context, ChatController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.pinkAccent,
                  onTap: () {
                    Get.back();
                    controller.sendImage(true);
                  },
                ),
                _buildAttachmentItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: AppColors.primary,
                  onTap: () {
                    Get.back();
                    controller.sendImage(false);
                  },
                ),
                _buildAttachmentItem(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Get.back();
                    controller.sendDocument();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

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

  void _openFullScreenImage(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  void _openDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open document',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _formatRecordTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
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
              backgroundImage: !controller.isGroup && controller.targetUser?.avatarUrl != null
                  ? NetworkImage(controller.targetUser!.avatarUrl!)
                  : null,
              child: controller.isGroup
                  ? const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20)
                  : (controller.targetUser?.avatarUrl == null
                      ? Text(
                          (controller.title.isNotEmpty ? controller.title[0] : 'C').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(
                    () => Text(
                      controller.isPartnerTyping.value
                          ? 'typing...'
                          : (controller.isGroup
                              ? 'Group Chat'
                              : (controller.targetUser?.isOnline == true ? 'Online' : 'Offline')),
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
              if (controller.targetUser == null) {
                Get.snackbar(
                  'Group Call',
                  'Group Voice Calling will be activated in Phase 6!',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              final callService = Get.find<CallService>();
              final authService = Get.find<AuthService>();
              if (authService.currentUser.value != null) {
                callService.startOutboundCall(
                  targetUser: controller.targetUser!,
                  currentUser: authService.currentUser.value!,
                  hasVideo: false,
                );
                Get.toNamed(Routes.CALL);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              if (controller.targetUser == null) {
                Get.snackbar(
                  'Group Call',
                  'Group Video Calling will be activated in Phase 6!',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              final callService = Get.find<CallService>();
              final authService = Get.find<AuthService>();
              if (authService.currentUser.value != null) {
                callService.startOutboundCall(
                  targetUser: controller.targetUser!,
                  currentUser: authService.currentUser.value!,
                  hasVideo: true,
                );
                Get.toNamed(Routes.CALL);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Uploading progress banner
            Obx(
              () => controller.isUploadingMedia.value
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      color: AppColors.primary.withAlpha(20),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Uploading media...',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    final isMe = message.senderId == controller.currentUserId;
                    final isImage = message.type == 'image' && message.mediaUrl != null;
                    final isAudio = message.type == 'audio' && message.mediaUrl != null;
                    final isFile = message.type == 'file' && message.mediaUrl != null;
                    final isCall = message.type == 'call';
                    final isMissed = (message.content ?? '').contains('Missed');
                    final senderName = message.sender?.displayName ?? message.sender?.username;
                    final memberColor = _getMemberColor(message.senderId);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => _showMessageOptions(context, controller, message, isMe),
                        onTap: isImage
                            ? () => _openFullScreenImage(message.mediaUrl!)
                            : (isFile ? () => _openDocument(message.mediaUrl!) : null),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          padding: isImage
                              ? const EdgeInsets.all(4)
                              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkChatBubbleReceiver
                                    : AppColors.lightChatBubbleReceiver),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
                              bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 30 : 6),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Show Sender Name ONLY in Group Chats for incoming messages (!isMe)
                                if (controller.isGroup && !isMe && senderName != null && senderName.isNotEmpty) ...[
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: memberColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],

                                if (isCall) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isMe
                                            ? Icons.call_made_rounded
                                            : (isMissed ? Icons.call_missed_rounded : Icons.call_received_rounded),
                                        size: 18,
                                        color: isMissed
                                            ? Colors.redAccent
                                            : (isMe ? Colors.white : AppColors.onlineGreen),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          message.content ?? 'Call',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: isMe
                                                ? Colors.white
                                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                ] else if (isFile) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.white.withAlpha(30) : AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file_rounded,
                                          color: isMe ? Colors.white : AppColors.primary,
                                          size: 26,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            message.content ?? 'Document',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isMe
                                                  ? Colors.white
                                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.download_rounded,
                                          color: isMe ? Colors.white70 : AppColors.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ] else if (isImage) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      message.mediaUrl!,
                                      fit: BoxFit.cover,
                                      width: 220,
                                      height: 180,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const SizedBox(
                                          width: 220,
                                          height: 180,
                                          child: Center(
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ] else if (isAudio) ...[
                                  VoiceNotePlayer(audioUrl: message.mediaUrl!, isMe: isMe),
                                  const SizedBox(height: 2),
                                ] else ...[
                                  Text(
                                    message.content ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe
                                          ? Colors.white
                                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],

                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        message.createdAt != null
                                            ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                                            : '',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: isMe
                                              ? Colors.white.withAlpha(180)
                                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                          size: 13,
                                          color: message.isRead ? AppColors.tickBlue : Colors.white.withAlpha(180),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Bottom Input Bar & Voice Recording Bar
            Obx(
              () => controller.isRecordingVoiceNote.value
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26),
                            onPressed: controller.cancelVoiceRecording,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Obx(
                            () => Text(
                              _formatRecordTime(controller.recordingSeconds.value),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: controller.stopAndSendVoiceNote,
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
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                            onPressed: () => _showAttachmentOptions(context, controller),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      controller.isEmojiPickerVisible.value
                                          ? Icons.keyboard_rounded
                                          : Icons.sentiment_satisfied_alt_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                    onPressed: controller.toggleEmojiPicker,
                                  ),
                                  Expanded(
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
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                            onPressed: controller.startVoiceRecording,
                          ),
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
            ),

            // In-App Emoji Picker Dock
            Obx(
              () => controller.isEmojiPickerVisible.value
                  ? SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          controller.onEmojiSelected(emoji.emoji);
                        },
                        config: Config(
                          height: 250,
                          checkPlatformCompatibility: true,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
