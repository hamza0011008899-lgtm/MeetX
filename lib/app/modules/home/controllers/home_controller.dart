import 'package:get/get.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../services/auth_service.dart';

class HomeController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ChatModel> chatList = <ChatModel>[].obs;
  final RxBool isLoading = true.obs;

  String get currentUserId => _authService.currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    loadUserChats();
  }

  /// Load user active conversation list
  Future<void> loadUserChats() async {
    isLoading.value = true;
    try {
      final chats = await _chatRepository.getUserChats();
      chatList.assignAll(chats);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load chat conversations.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
