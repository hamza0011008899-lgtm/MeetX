import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class CallService extends GetxService {
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  final RxBool isMuted = false.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxBool isFrontCamera = true.obs;
  final RxBool isSpeakerOn = true.obs;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// Initialize WebRTC Peer Connection and local media stream
  Future<void> initializeCall({required bool hasVideo}) async {
    try {
      isVideoEnabled.value = hasVideo;
      isMuted.value = false;

      // 1. Create WebRTC Peer Connection with Google STUN servers
      peerConnection = await createPeerConnection(_iceServers);

      // 2. Get local camera / audio media stream
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': hasVideo
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = localStream;

      // Add local stream tracks to PeerConnection
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Listen for remote tracks
      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          remoteRenderer.srcObject = remoteStream;
        }
      };
    } catch (e) {
      debugPrint('DEBUG initializeCall error: $e');
    }
  }

  /// Mute / Unmute local microphone
  void toggleMute() {
    if (localStream != null) {
      final audioTracks = localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final bool current = audioTracks.first.enabled;
        audioTracks.first.enabled = !current;
        isMuted.value = !current;
      }
    }
  }

  /// Enable / Disable local camera video stream
  void toggleVideo() {
    if (localStream != null) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final bool current = videoTracks.first.enabled;
        videoTracks.first.enabled = !current;
        isVideoEnabled.value = !current;
      }
    }
  }

  /// Switch front / rear camera
  Future<void> switchCamera() async {
    if (localStream != null) {
      final videoTracks = localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks.first);
        isFrontCamera.value = !isFrontCamera.value;
      }
    }
  }

  /// Clean up media streams and renderers
  Future<void> endCall() async {
    try {
      localStream?.getTracks().forEach((track) => track.stop());
      localStream?.dispose();
      remoteStream?.dispose();
      await peerConnection?.close();
      peerConnection = null;
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (e) {
      debugPrint('DEBUG endCall error: $e');
    }
  }

  @override
  void onClose() {
    endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.onClose();
  }
}
