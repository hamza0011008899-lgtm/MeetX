import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/call_service.dart';
import '../../../theme/app_colors.dart';

class CallView extends StatefulWidget {
  const CallView({super.key});

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  final CallService _callService = Get.find<CallService>();
  Timer? _timer;
  int _callSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCallTimer();
  }

  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callSeconds++;
        });
      }
    });
  }

  String _formatCallDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161224),
      body: Obx(() {
        final call = _callService.currentCall.value;
        if (call == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute == Routes.CALL) {
              Get.back();
            }
          });
          return const SizedBox.shrink();
        }

        final isVideo = _callService.isVideoEnabled.value;

        return Stack(
          children: [
            // Remote Video or Voice Gradient Background
            Positioned.fill(
              child: isVideo && _callService.remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _callService.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF2C1B4D),
                            Color(0xFF120E1F),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(100),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: AppColors.primary,
                              backgroundImage: call.callerAvatar != null
                                  ? NetworkImage(call.callerAvatar!)
                                  : null,
                              child: call.callerAvatar == null
                                  ? Text(
                                      (call.callerName.isNotEmpty ? call.callerName[0] : 'C').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            call.callerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCallDuration(_callSeconds),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Local Camera PIP (Picture in Picture) Card for Video Calls
            if (isVideo && _callService.localRenderer.srcObject != null)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RTCVideoView(
                      _callService.localRenderer,
                      mirror: _callService.isFrontCamera.value,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Top Status Bar Overlay
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.onlineGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCallDuration(_callSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom In-Call Control Toolbar
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Speakerphone Toggle Button
                    Obx(
                      () => CircleAvatar(
                        radius: 24,
                        backgroundColor: !_callService.isSpeakerOn.value
                            ? Colors.redAccent.withAlpha(200)
                            : Colors.white.withAlpha(40),
                        child: IconButton(
                          icon: Icon(
                            _callService.isSpeakerOn.value
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _callService.toggleSpeaker,
                        ),
                      ),
                    ),

                    // Mic Mute Toggle Button
                    Obx(
                      () => CircleAvatar(
                        radius: 24,
                        backgroundColor: _callService.isMuted.value
                            ? Colors.redAccent.withAlpha(200)
                            : Colors.white.withAlpha(40),
                        child: IconButton(
                          icon: Icon(
                            _callService.isMuted.value
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _callService.toggleMute,
                        ),
                      ),
                    ),

                    // Video Camera Toggle Button
                    Obx(
                      () => CircleAvatar(
                        radius: 24,
                        backgroundColor: !_callService.isVideoEnabled.value
                            ? Colors.redAccent.withAlpha(200)
                            : Colors.white.withAlpha(40),
                        child: IconButton(
                          icon: Icon(
                            _callService.isVideoEnabled.value
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _callService.toggleVideo,
                        ),
                      ),
                    ),

                    // Switch Camera Front / Back Button
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: IconButton(
                        icon: const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _callService.switchCamera,
                      ),
                    ),

                    // End Call Button
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.redAccent,
                      child: IconButton(
                        icon: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          _callService.endCall();
                          Get.back();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
