import 'package:get/get.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/chat/views/group_create_view.dart';
import '../modules/chat/views/user_search_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
    ),
    GetPage(
      name: _Paths.USER_SEARCH,
      page: () => const UserSearchView(),
    ),
    GetPage(
      name: _Paths.GROUP_CREATE,
      page: () => const GroupCreateView(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
    ),
  ];
}
