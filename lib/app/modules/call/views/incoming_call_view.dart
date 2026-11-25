import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/call_service.dart';
import '../../../theme/app_colors.dart';

class IncomingCallView extends StatelessWidget {
  const IncomingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    final callService = Get.find<CallService>();

    return Scaffold(
      backgroundColor: const Color(0xFF161224),
      body: Obx(() {
        final call = callService.currentCall.value;
        if (call == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute == Routes.INCOMING_CALL) {
              Get.back();
            }
          });
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
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
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 40),

                // Caller Avatar & Name
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(120),
                            blurRadius: 30,
                            spreadRadius: 10,
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
                    const SizedBox(height: 24),
                    Text(
                      call.callerName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          call.hasVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          call.hasVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withAlpha(180),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Decline & Accept Action Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Decline Call Button
                      GestureDetector(
                        onTap: () {
                          callService.declineCall(call);
                          Get.back();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withAlpha(100),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Decline',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // Accept Call Button
                      GestureDetector(
                        onTap: () async {
                          await callService.acceptCall(call);
                          Get.offNamed(Routes.CALL);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.onlineGreen.withAlpha(100),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Accept',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
