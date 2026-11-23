import 'message_model.dart';
import 'user_model.dart';

class ChatModel {
  final String id;
  final bool isGroup;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final int unreadCount;

  ChatModel({
    required this.id,
    this.isGroup = false,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
  });

  /// Helper getter to find the other user in a 1-on-1 chat
  UserModel? getOtherUser(String currentUserId) {
    if (participants.isEmpty) return null;
    return participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Dynamic chat title: returns Group Name or Partner's Display Name
  String getChatTitle(String currentUserId) {
    if (isGroup && name != null && name!.isNotEmpty) {
      return name!;
    }
    final partner = getOtherUser(currentUserId);
    if (partner != null) {
      return partner.displayName ?? partner.username;
    }
    return 'Chat';
  }

  /// Dynamic avatar URL: returns partner's avatar URL for 1-on-1 chats
  String? getChatAvatar(String currentUserId) {
    if (!isGroup) {
      return getOtherUser(currentUserId)?.avatarUrl;
    }
    return null;
  }

  /// Factory constructor to deserialize Supabase JSON map into ChatModel
  factory ChatModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    List<UserModel>? participantsList,
    MessageModel? latestMessage,
    int unreadCount = 0,
  }) {
    return ChatModel(
      id: json['id'] as String,
      isGroup: json['is_group'] as bool? ?? false,
      name: json['name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      participants: participantsList ?? [],
      lastMessage: latestMessage,
      unreadCount: unreadCount,
    );
  }

  /// Convert ChatModel instance to JSON Map for database inserts
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_group': isGroup,
      'name': name,
    };
  }

  /// Create a copy of ChatModel with updated fields
  ChatModel copyWith({
    String? id,
    bool? isGroup,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserModel>? participants,
    MessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
