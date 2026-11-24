import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final authService = Get.find<AuthService>();
    final authRepository = AuthRepository();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'MeetX',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
              onPressed: () => Get.toNamed(Routes.USER_SEARCH),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'group') {
                  Get.toNamed(Routes.GROUP_CREATE);
                } else if (value == 'logout') {
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
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'group',
                  child: Row(
                    children: [
                      Icon(Icons.group_add_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('New Group'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Status'),
              Tab(text: 'Calls'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Chats
            _buildChatsTab(context, controller, authService, isDark),

            // TAB 2: Status (Placeholder for Phase 4/Status updates)
            _buildStatusTab(context, isDark),

            // TAB 3: Calls (Placeholder for Phase 6 WebRTC Calls)
            _buildCallsTab(context, isDark),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.toNamed(Routes.USER_SEARCH),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('New Chat'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChatsTab(
    BuildContext context,
    HomeController controller,
    AuthService authService,
    bool isDark,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.chatList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 72,
                color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "New Chat" to start messaging!',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadUserChats,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: controller.chatList.length,
          itemBuilder: (context, index) {
            final chat = controller.chatList[index];
            final title = chat.getChatTitle(authService.currentUser.value?.id ?? '');
            final avatar = chat.getChatAvatar(authService.currentUser.value?.id ?? '');
            final partner = chat.getOtherUser(authService.currentUser.value?.id ?? '');

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withAlpha(40),
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              title[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    if (partner?.isOnline == true && !chat.isGroup)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: AppColors.onlineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  chat.lastMessage?.content ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (chat.lastMessage?.createdAt != null)
                      Text(
                        '${chat.lastMessage!.createdAt!.hour.toString().padLeft(2, '0')}:${chat.lastMessage!.createdAt!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (chat.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${chat.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Get.toNamed(
                    Routes.CHAT,
                    arguments: {
                      'chatId': chat.id,
                      'targetUser': partner,
                    },
                  )?.then((_) => controller.loadUserChats());
                },
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildStatusTab(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.donut_large_rounded,
            size: 64,
            color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Status Updates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share stories with your contacts',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_call,
            size: 64,
            color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Calls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Voice and Video call history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
