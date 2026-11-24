import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MediaService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

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
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.isNotEmpty && result.first.path != null) {
        return File(result.first.path!);
      }
    } catch (e) {
      debugPrint('DEBUG pickDocument error: $e');
    }
    return null;
  }

  /// Start recording voice note
  Future<bool> startAudioRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        return true;
      }
    } catch (e) {
      debugPrint('DEBUG startAudioRecording error: $e');
    }
    return false;
  }

  /// Stop audio recording and return recorded file
  Future<File?> stopAudioRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        return File(path);
      }
    } catch (e) {
      debugPrint('DEBUG stopAudioRecording error: $e');
    }
    return null;
  }

  /// Cancel current audio recording
  Future<void> cancelAudioRecording() async {
    try {
      await _audioRecorder.stop();
    } catch (_) {}
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

  @override
  void onClose() {
    _audioRecorder.dispose();
    super.onClose();
  }
}
