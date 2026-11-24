import 'user_model.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String type; // 'text', 'image', 'audio', 'video', 'file'
  final String? mediaUrl;
  final bool isRead;
  final DateTime? createdAt;
  final UserModel? sender;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.type = 'text',
    this.mediaUrl,
    this.isRead = false,
    this.createdAt,
    this.sender,
  });

  /// Factory constructor to deserialize Supabase JSON map into MessageModel
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      type: json['type'] as String? ?? 'text',
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      sender: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert MessageModel instance to JSON Map for database inserts
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'is_read': isRead,
    };
  }

  /// Create a copy of MessageModel with updated fields
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? type,
    String? mediaUrl,
    bool? isRead,
    DateTime? createdAt,
    UserModel? sender,
  })

  {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }
}
