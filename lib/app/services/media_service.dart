import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MediaService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('DEBUG pickImageFromGallery error: $e');
    }
    return null;
  }

  /// Snap an image using camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('DEBUG pickImageFromCamera error: $e');
    }
    return null;
  }

  /// Pick a video file
  Future<File?> pickVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint('DEBUG pickVideo error: $e');
    }
    return null;
  }

  /// Pick any document file (.pdf, .doc, .zip, etc.)
  Future<File?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('DEBUG pickDocument error: $e');
    }
    return null;
  }

  /// Upload file to Supabase Storage bucket and return public URL
  Future<String?> uploadMedia({
    required File file,
    required String bucketName,
    required String path,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      await _client.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              cacheControl: '3600',
            ),
          );

      final String publicUrl = _client.storage.from(bucketName).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('DEBUG uploadMedia error: $e');
      return null;
    }
  }
}
