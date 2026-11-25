import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Helper to get local user media without symbol collision with GetX navigator
Future<MediaStream> getWebRtcUserMedia(Map<String, dynamic> constraints) {
  return navigator.mediaDevices.getUserMedia(constraints);
}
