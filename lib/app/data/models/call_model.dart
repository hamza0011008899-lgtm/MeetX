class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final bool hasVideo;
  final String status; // dialing, ringing, accepted, declined, ended
  final DateTime? createdAt;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.hasVideo,
    required this.status,
    this.createdAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String? ?? '',
      callerId: json['caller_id'] as String? ?? '',
      callerName: json['caller_name'] as String? ?? 'Caller',
      callerAvatar: json['caller_avatar'] as String?,
      receiverId: json['receiver_id'] as String? ?? '',
      hasVideo: json['has_video'] as bool? ?? false,
      status: json['status'] as String? ?? 'dialing',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'receiver_id': receiverId,
      'has_video': hasVideo,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    bool? hasVideo,
    String? status,
    DateTime? createdAt,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      hasVideo: hasVideo ?? this.hasVideo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  just in time you know i want you badly in my life in this whole fucking universe i want to be a good developer but i dont know where to start and where to end i
}
