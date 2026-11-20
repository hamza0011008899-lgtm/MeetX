import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/auth_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Wait for splash animation to display nicely (5 seconds)
    await Future.delayed(const Duration(milliseconds: 5000));

    final authService = Get.find<AuthService>();

    if (authService.isAuthenticated) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
