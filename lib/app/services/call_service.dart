import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/call_model.dart';
import '../data/models/user_model.dart';
import '../routes/app_pages.dart';
import 'supabase_service.dart';
import 'webrtc_helper.dart';

class CallService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  final RxBool isMuted = false.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxBool isFrontCamera = true.obs;
  final RxBool isSpeakerOn = true.obs;

  final Rx<CallModel?> currentCall = Rx<CallModel?>(null);
  RealtimeChannel? _signalingChannel;

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

  /// Listen for incoming calls on user's dedicated broadcast channel
  void listenForIncomingCalls(String myUserId) {
    if (myUserId.isEmpty) return;

    _signalingChannel?.unsubscribe();
    _signalingChannel = _client.channel('calls:$myUserId');

    _signalingChannel?.onBroadcast(
      event: 'call_invite',
      callback: (payload) async {
        final callData = payload['call'] as Map<String, dynamic>?;
        if (callData != null) {
          final incoming = CallModel.fromJson(callData);
          currentCall.value = incoming;
          if (Get.currentRoute != Routes.INCOMING_CALL) {
            Get.toNamed(Routes.INCOMING_CALL);
          }
        }
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'sdp_offer',
      callback: (payload) async {
        final sdp = payload['sdp'] as String?;
        final type = payload['type'] as String?;
        if (sdp != null && type != null && peerConnection != null) {
          await peerConnection!.setRemoteDescription(
            RTCSessionDescription(sdp, type),
          );
          // Create SDP Answer
          final answer = await peerConnection!.createAnswer();
          await peerConnection!.setLocalDescription(answer);

          _sendBroadcastSignal(
            targetUserId: currentCall.value?.callerId ?? '',
            event: 'sdp_answer',
            payload: {
              'sdp': answer.sdp,
              'type': answer.type,
            },
          );
        }
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'sdp_answer',
      callback: (payload) async {
        final sdp = payload['sdp'] as String?;
        final type = payload['type'] as String?;
        if (sdp != null && type != null && peerConnection != null) {
          await peerConnection!.setRemoteDescription(
            RTCSessionDescription(sdp, type),
          );
        }
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'ice_candidate',
      callback: (payload) async {
        final candidate = payload['candidate'] as Map<String, dynamic>?;
        if (candidate != null && peerConnection != null) {
          await peerConnection!.addCandidate(
            RTCIceCandidate(
              candidate['candidate'] as String?,
              candidate['sdpMid'] as String?,
              candidate['sdpMLineIndex'] as int?,
            ),
          );
        }
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'call_declined',
      callback: (_) {
        endCall();
        debugPrint('DEBUG Call declined by remote user');
      },
    );

    _signalingChannel?.onBroadcast(
      event: 'call_ended',
      callback: (_) {
        endCall();
      },
    );

    _signalingChannel?.subscribe();
  }

  /// Send broadcast signal helper
  void _sendBroadcastSignal({
    required String targetUserId,
    required String event,
    required Map<String, dynamic> payload,
  }) {
    final targetChannel = _client.channel('calls:$targetUserId');
    targetChannel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        targetChannel.sendBroadcastMessage(
          event: event,
          payload: payload,
        );
      }
    });
  }

  /// Start outbound call to target user
  Future<void> startOutboundCall({
    required UserModel targetUser,
    required UserModel currentUser,
    required bool hasVideo,
  }) async {
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final call = CallModel(
      id: callId,
      callerId: currentUser.id,
      callerName: currentUser.displayName ?? currentUser.username,
      callerAvatar: currentUser.avatarUrl,
      receiverId: targetUser.id,
      hasVideo: hasVideo,
      status: 'ringing',
      createdAt: DateTime.now(),
    );

    currentCall.value = call;

    // 1. Initialize local media stream
    await initializeMedia(hasVideo: hasVideo);

    // 2. Broadcast call invitation to target user
    _sendBroadcastSignal(
      targetUserId: targetUser.id,
      event: 'call_invite',
      payload: {'call': call.toJson()},
    );

    // 3. Create SDP Offer
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    _sendBroadcastSignal(
      targetUserId: targetUser.id,
      event: 'sdp_offer',
      payload: {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    );
  }

  /// Accept an incoming call
  Future<void> acceptCall(CallModel call) async {
    currentCall.value = call.copyWith(status: 'accepted');
    await initializeMedia(hasVideo: call.hasVideo);
  }

  /// Decline an incoming call
  void declineCall(CallModel call) {
    _sendBroadcastSignal(
      targetUserId: call.callerId,
      event: 'call_declined',
      payload: {'callId': call.id},
    );
    endCall();
  }

  /// Initialize WebRTC Media Streams & PeerConnection
  Future<void> initializeMedia({required bool hasVideo}) async {
    try {
      isVideoEnabled.value = hasVideo;
      isMuted.value = false;

      peerConnection = await createPeerConnection(_iceServers);

      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        final targetId = currentCall.value?.callerId == _client.auth.currentUser?.id
            ? currentCall.value?.receiverId
            : currentCall.value?.callerId;

        if (targetId != null) {
          _sendBroadcastSignal(
            targetUserId: targetId,
            event: 'ice_candidate',
            payload: {'candidate': candidate.toMap()},
          );
        }
      };

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

      localStream = await getWebRtcUserMedia(mediaConstraints);
      localRenderer.srcObject = localStream;

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          remoteRenderer.srcObject = remoteStream;
        }
      };
    } catch (e) {
      debugPrint('DEBUG initializeMedia error: $e');
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

  /// End and clean up active call
  Future<void> endCall() async {
    try {
      final targetId = currentCall.value?.callerId == _client.auth.currentUser?.id
          ? currentCall.value?.receiverId
          : currentCall.value?.callerId;

      if (targetId != null) {
        _sendBroadcastSignal(
          targetUserId: targetId,
          event: 'call_ended',
          payload: {'callId': currentCall.value?.id},
        );
      }

      localStream?.getTracks().forEach((track) => track.stop());
      localStream?.dispose();
      remoteStream?.dispose();
      await peerConnection?.close();
      peerConnection = null;
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      currentCall.value = null;
    } catch (e) {
      debugPrint('DEBUG endCall error: $e');
    }
  }

  @override
  void onClose() {
    endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _signalingChannel?.unsubscribe();
    super.onClose();
  }
}
