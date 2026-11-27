import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/call_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/chat_repository.dart';
import '../modules/home/controllers/home_controller.dart';
import '../routes/app_pages.dart';
import 'supabase_service.dart';
import 'webrtc_helper.dart';

class CallService extends GetxService {
  final SupabaseClient _client = Get.find<SupabaseService>().client;
  final ChatRepository _chatRepository = ChatRepository();

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
  String _myUserId = '';
  DateTime? _callStartTime;
  Timer? _ringingTimeoutTimer;

  final List<RTCIceCandidate> _pendingIceCandidates = [];

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      {'urls': 'stun:stun.services.mozilla.com'},
    ]
  };

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (e) {
      debugPrint('DEBUG _initRenderers error: $e');
    }
  }

  /// Listen for incoming calls on global signaling channel
  void listenForIncomingCalls(String myUserId) {
    if (myUserId.isEmpty) return;
    _myUserId = myUserId;

    if (_signalingChannel != null) return;

    _signalingChannel = _client.channel('public:signaling');

    // 1. Incoming Call Invitation
    _signalingChannel?.onBroadcast(
      event: 'call_invite',
      callback: (payload) async {
        final receiverId = payload['receiver_id'] as String?;
        if (receiverId == _myUserId) {
          final callData = payload['call'] as Map<String, dynamic>?;
          if (callData != null) {
            final incoming = CallModel.fromJson(callData);
            currentCall.value = incoming;
            if (Get.currentRoute != Routes.INCOMING_CALL) {
              Get.toNamed(Routes.INCOMING_CALL);
            }
          }
        }
      },
    );

    // 2. Call Accepted by Receiver -> Caller creates SDP Offer
    _signalingChannel?.onBroadcast(
      event: 'call_accepted',
      callback: (payload) async {
        final callerId = payload['caller_id'] as String?;
        if (callerId == _myUserId && peerConnection != null) {
          _ringingTimeoutTimer?.cancel();
          _callStartTime = DateTime.now();
          final receiverId = payload['receiver_id'] as String?;

          debugPrint('DEBUG Call accepted by receiver, creating SDP offer...');
          final offer = await peerConnection!.createOffer();
          await peerConnection!.setLocalDescription(offer);

          _sendBroadcastSignal(
            event: 'sdp_offer',
            payload: {
              'receiver_id': receiverId,
              'sdp': offer.sdp,
              'type': offer.type,
            },
          );
        }
      },
    );

    // 3. Receiver receives SDP Offer -> creates SDP Answer
    _signalingChannel?.onBroadcast(
      event: 'sdp_offer',
      callback: (payload) async {
        final receiverId = payload['receiver_id'] as String?;
        if (receiverId == _myUserId && peerConnection != null) {
          _ringingTimeoutTimer?.cancel();
          _callStartTime = DateTime.now();
          final sdp = payload['sdp'] as String?;
          final type = payload['type'] as String?;
          if (sdp != null && type != null) {
            debugPrint('DEBUG Received SDP offer, setting remote description...');
            await peerConnection!.setRemoteDescription(
              RTCSessionDescription(sdp, type),
            );
            _drainPendingIceCandidates();

            final answer = await peerConnection!.createAnswer();
            await peerConnection!.setLocalDescription(answer);

            _sendBroadcastSignal(
              event: 'sdp_answer',
              payload: {
                'caller_id': currentCall.value?.callerId,
                'sdp': answer.sdp,
                'type': answer.type,
              },
            );
          }
        }
      },
    );

    // 4. Caller receives SDP Answer
    _signalingChannel?.onBroadcast(
      event: 'sdp_answer',
      callback: (payload) async {
        final callerId = payload['caller_id'] as String?;
        if (callerId == _myUserId && peerConnection != null) {
          final sdp = payload['sdp'] as String?;
          final type = payload['type'] as String?;
          if (sdp != null && type != null) {
            debugPrint('DEBUG Received SDP answer, setting remote description...');
            await peerConnection!.setRemoteDescription(
              RTCSessionDescription(sdp, type),
            );
            _drainPendingIceCandidates();
          }
        }
      },
    );

    // 5. ICE Candidate Exchange
    _signalingChannel?.onBroadcast(
      event: 'ice_candidate',
      callback: (payload) async {
        final targetId = payload['target_id'] as String?;
        if (targetId == _myUserId) {
          final candidateMap = payload['candidate'] as Map<String, dynamic>?;
          if (candidateMap != null) {
            final candidate = RTCIceCandidate(
              candidateMap['candidate'] as String?,
              candidateMap['sdpMid'] as String?,
              candidateMap['sdpMLineIndex'] as int?,
            );

            if (peerConnection != null && peerConnection!.getRemoteDescription() != null) {
              await peerConnection!.addCandidate(candidate);
            } else {
              _pendingIceCandidates.add(candidate);
            }
          }
        }
      },
    );

    // 6. Call Declined
    _signalingChannel?.onBroadcast(
      event: 'call_declined',
      callback: (payload) async {
        final targetId = payload['target_id'] as String?;
        if (targetId == _myUserId) {
          _ringingTimeoutTimer?.cancel();
          await endCall(isMissedOverride: true);
          Get.snackbar(
            'Call Declined',
            'User declined the call.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );

    // 7. Call Ended
    _signalingChannel?.onBroadcast(
      event: 'call_ended',
      callback: (payload) async {
        final targetId = payload['target_id'] as String?;
        if (targetId == _myUserId) {
          _ringingTimeoutTimer?.cancel();
          await endCall();
        }
      },
    );

    _signalingChannel?.subscribe();
  }

  /// Drain queued ICE candidates once remote description is set
  Future<void> _drainPendingIceCandidates() async {
    if (peerConnection == null) return;
    for (final candidate in _pendingIceCandidates) {
      await peerConnection!.addCandidate(candidate);
    }
    _pendingIceCandidates.clear();
  }

  /// Log call activity to chat database
  Future<void> _logCallInChat(CallModel call, {required bool isMissed}) async {
    try {
      final currentUid = _client.auth.currentUser?.id ?? _myUserId;
      if (currentUid.isEmpty) {
        debugPrint('DEBUG _logCallInChat skipped: currentUid is empty');
        return;
      }

      final targetUserId = call.callerId == currentUid ? call.receiverId : call.callerId;
      if (targetUserId.isEmpty || targetUserId == currentUid) {
        debugPrint('DEBUG _logCallInChat skipped: invalid targetUserId $targetUserId');
        return;
      }

      debugPrint('DEBUG _logCallInChat starting for target: $targetUserId');
      final chatId = await _chatRepository.getOrCreateSingleChat(targetUserId);

      String content;
      if (isMissed || _callStartTime == null) {
        content = call.hasVideo ? '📹 Missed video call' : '📞 Missed voice call';
      } else {
        final durationSeconds = DateTime.now().difference(_callStartTime!).inSeconds;
        final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
        final secs = (durationSeconds % 60).toString().padLeft(2, '0');
        content = call.hasVideo
            ? '📹 Video call ($mins:$secs)'
            : '📞 Voice call ($mins:$secs)';
      }

      final msg = await _chatRepository.sendMessage(
        chatId: chatId,
        content: content,
        type: 'call',
      );
      debugPrint('DEBUG _logCallInChat SUCCESS msgId: ${msg.id}, content: $content');
    } catch (e, stack) {
      debugPrint('DEBUG _logCallInChat EXCEPTION: $e\n$stack');
    }
  }

  /// Send broadcast signal helper
  void _sendBroadcastSignal({
    required String event,
    required Map<String, dynamic> payload,
  }) {
    if (_signalingChannel != null) {
      _signalingChannel!.sendBroadcastMessage(
        event: event,
        payload: payload,
      );
    }
  }

  /// Start outbound call to target user
  Future<void> startOutboundCall({
    required UserModel targetUser,
    required UserModel currentUser,
    required bool hasVideo,
  }) async {
    _callStartTime = null;
    _myUserId = currentUser.id;
    _pendingIceCandidates.clear();

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
      event: 'call_invite',
      payload: {
        'receiver_id': targetUser.id,
        'call': call.toJson(),
      },
    );

    // 3. Start 30-Second Ringing Timeout Timer
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (currentCall.value != null && _callStartTime == null) {
        debugPrint('DEBUG Ringing timeout - no answer after 30 seconds');
        Get.snackbar(
          'No Answer',
          'User did not answer the call.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        declineCall(call);
      }
    });
  }

  /// Accept an incoming call
  Future<void> acceptCall(CallModel call) async {
    _ringingTimeoutTimer?.cancel();
    _callStartTime = DateTime.now();
    _pendingIceCandidates.clear();
    currentCall.value = call.copyWith(status: 'accepted');

    // 1. Initialize local media stream & peerConnection
    await initializeMedia(hasVideo: call.hasVideo);

    // 2. Broadcast call_accepted event to Caller
    _sendBroadcastSignal(
      event: 'call_accepted',
      payload: {
        'caller_id': call.callerId,
        'receiver_id': _myUserId,
      },
    );
  }

  /// Decline an incoming call
  void declineCall(CallModel call) async {
    _ringingTimeoutTimer?.cancel();
    _sendBroadcastSignal(
      event: 'call_declined',
      payload: {
        'target_id': call.callerId,
        'callId': call.id,
      },
    );
    await endCall(isMissedOverride: true);
  }

  /// Initialize WebRTC Media Streams & PeerConnection
  Future<void> initializeMedia({required bool hasVideo}) async {
    try {
      isVideoEnabled.value = hasVideo;
      isMuted.value = false;
      isSpeakerOn.value = true;

      await Helper.setSpeakerphoneOn(true);

      peerConnection = await createPeerConnection(_iceServers);

      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        final targetId = currentCall.value?.callerId == _client.auth.currentUser?.id
            ? currentCall.value?.receiverId
            : currentCall.value?.callerId;

        if (targetId != null) {
          _sendBroadcastSignal(
            event: 'ice_candidate',
            payload: {
              'target_id': targetId,
              'candidate': candidate.toMap(),
            },
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
        debugPrint('DEBUG onTrack kind: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          remoteRenderer.srcObject = remoteStream;
        }
      };

      peerConnection?.onAddStream = (MediaStream stream) {
        debugPrint('DEBUG onAddStream received id: ${stream.id}');
        remoteStream = stream;
        remoteRenderer.srcObject = remoteStream;
      };
    } catch (e) {
      debugPrint('DEBUG initializeMedia error: $e');
    }
  }

  /// Toggle Speakerphone On / Off
  Future<void> toggleSpeaker() async {
    try {
      final bool nextState = !isSpeakerOn.value;
      await Helper.setSpeakerphoneOn(nextState);
      isSpeakerOn.value = nextState;
    } catch (e) {
      debugPrint('DEBUG toggleSpeaker error: $e');
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
  Future<void> endCall({bool isMissedOverride = false}) async {
    try {
      _ringingTimeoutTimer?.cancel();

      final call = currentCall.value;
      if (call != null) {
        final isMissed = isMissedOverride || _callStartTime == null;
        await _logCallInChat(call, isMissed: isMissed);

        final targetId = call.callerId == _myUserId ? call.receiverId : call.callerId;
        _sendBroadcastSignal(
          event: 'call_ended',
          payload: {
            'target_id': targetId,
            'callId': call.id,
          },
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
      _callStartTime = null;
      _pendingIceCandidates.clear();

      // Refresh Home View Chats and Calls Tabs
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadCallHistory();
        homeController.loadUserChats();
      }
    } catch (e) {
      debugPrint('DEBUG endCall error: $e');
    }
  }

  @override
  void onClose() {
    _ringingTimeoutTimer?.cancel();
    endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _signalingChannel?.unsubscribe();
    super.onClose();
  }
}
