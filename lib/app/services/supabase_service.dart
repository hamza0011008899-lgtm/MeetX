import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService {
  late final SupabaseClient client;

  Future<SupabaseService> init() async {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // Initialize Supabase if credentials are provided
    if (url.isNotEmpty && anonKey.isNotEmpty && url != 'YOUR_SUPABASE_URL_HERE') {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      client = Supabase.instance.client;
    }

    return this;
  }
}
