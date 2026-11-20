class UserModel {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? statusMessage;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.statusMessage,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

  /// Factory constructor to create a UserModel from Supabase JSON map
  factory UserModel.fromJson(Map<String, dynamic> json, {String? userEmail}) {
    return UserModel(
      id: json['id'] as String,
      email: userEmail ?? json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      statusMessage: json['status_message'] as String? ?? 'Hey there! I am using MeetX.',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  /// Converts UserModel instance to a JSON Map for database inserts/updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'status_message': statusMessage,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  /// Helper to create a copy of UserModel with modified fields
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? statusMessage,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
