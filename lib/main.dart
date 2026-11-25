import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/services/auth_service.dart';
import 'app/services/call_service.dart';
import 'app/services/media_service.dart';
import 'app/services/supabase_service.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global services in order
  await Get.putAsync(() => SupabaseService().init());
  Get.put(CallService());
  Get.put(MediaService());
  await Get.putAsync(() => AuthService().init());

  runApp(const MeetXApp());
}

class MeetXApp extends StatelessWidget {
  const MeetXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MeetX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
