import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatRepository {
  final SupabaseClient _client = Get.find<SupabaseService>().client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch profile by user ID
  Future<UserModel?> getProfileById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('DEBUG getProfileById error: $e');
      return null;
    }
  }

  /// Fetch all users or search by query
  Future<List<UserModel>> searchUsers(String query) async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final q = query.trim();
      if (q.isEmpty) {
        final response = await _client
            .from('profiles')
            .select()
            .neq('id', uid)
            .limit(30);
        return (response as List).map((json) => UserModel.fromJson(json)).toList();
      }

      final response = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$q%,display_name.ilike.%$q%')
          .neq('id', uid)
          .limit(30);

      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('DEBUG searchUsers error: $e');
      try {
        final fallbackResponse = await _client
            .from('profiles')
            .select()
            .neq('id', uid)
            .limit(30);
        return (fallbackResponse as List).map((json) => UserModel.fromJson(json)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Get or Create a 1-on-1 chat room with another user
  Future<String> getOrCreateSingleChat(String otherUserId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      // 1. Check if a private chat already exists between these two users
      final myChatsResponse = await _client
          .from('chat_participants')
          .select('chat_id, chats!inner(is_group)')
          .eq('user_id', uid)
          .eq('chats.is_group', false);

      final myChatIds = (myChatsResponse as List)
          .map((e) => e['chat_id'] as String)
          .toList();

      if (myChatIds.isNotEmpty) {
        final sharedChatResponse = await _client
            .from('chat_participants')
            .select('chat_id')
            .eq('user_id', otherUserId)
            .filter('chat_id', 'in', myChatIds)
            .maybeSingle();

        if (sharedChatResponse != null) {
          return sharedChatResponse['chat_id'] as String;
        }
      }

      // 2. If no chat exists, create a new chat entry
      final newChatResponse = await _client
          .from('chats')
          .insert({'is_group': false})
          .select('id')
          .single();

      final newChatId = newChatResponse['id'] as String;

      // 3. Add both users to chat_participants
      await _client.from('chat_participants').insert([
        {'chat_id': newChatId, 'user_id': uid},
        {'chat_id': newChatId, 'user_id': otherUserId},
      ]);

      return newChatId;
    } catch (e) {
      debugPrint('DEBUG getOrCreateSingleChat error: $e');
      rethrow;
    }
  }

  /// Create a Group Chat room with multiple members
  Future<String> createGroupChat(String groupName, List<String> memberIds) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      // 1. Create group entry in chats table
      final newChatResponse = await _client
          .from('chats')
          .insert({'is_group': true, 'name': groupName})
          .select('id')
          .single();

      final newChatId = newChatResponse['id'] as String;

      // 2. Ensure creator is in participants
      final allMemberIds = {uid, ...memberIds}.toList();

      final participantRows = allMemberIds
          .map((memberId) => {'chat_id': newChatId, 'user_id': memberId})
          .toList();

      await _client.from('chat_participants').insert(participantRows);

      return newChatId;
    } catch (e) {
      debugPrint('DEBUG createGroupChat error: $e');
      rethrow;
    }
  }

  /// Fetch all active chat rooms for the logged-in user
  Future<List<ChatModel>> getUserChats() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      // 1. Fetch user's chat IDs
      final myChatsResponse = await _client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', uid);

      final chatIds = (myChatsResponse as List)
          .map((e) => e['chat_id'] as String)
          .toList();

      if (chatIds.isEmpty) return [];

      // 2. Fetch details for each chat room
      final List<ChatModel> chatList = [];

      for (final chatId in chatIds) {
        final chatData = await _client
            .from('chats')
            .select()
            .eq('id', chatId)
            .maybeSingle();

        if (chatData == null) continue;

        // Fetch participants for this chat
        final participantsResponse = await _client
            .from('chat_participants')
            .select('profiles(*)')
            .eq('chat_id', chatId);

        final List<UserModel> participants = [];
        for (final row in participantsResponse as List) {
          if (row['profiles'] != null) {
            participants.add(UserModel.fromJson(row['profiles'] as Map<String, dynamic>));
          }
        }

        // Fetch latest message
        final latestMessageResponse = await _client
            .from('messages')
            .select('*, profiles(*)')
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        MessageModel? latestMessage;
        if (latestMessageResponse != null) {
          latestMessage = MessageModel.fromJson(latestMessageResponse);
        }

        // Fetch unread count for current user
        final unreadCountResponse = await _client
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', uid)
            .eq('is_read', false);

        final unreadCount = (unreadCountResponse as List).length;

        chatList.add(
          ChatModel.fromJson(
            chatData,
            currentUserId: uid,
            participantsList: participants,
            latestMessage: latestMessage,
            unreadCount: unreadCount,
          ),
        );
      }

      // Sort chats by most recent message / update timestamp
      chatList.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.updatedAt ?? DateTime(1970);
        final bTime = b.lastMessage?.createdAt ?? b.updatedAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return chatList;
    } catch (e) {
      debugPrint('DEBUG getUserChats error: $e');
      return [];
    }
  }

  /// Fetch message history for a specific chat room
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    try {
      final response = await _client
          .from('messages')
          .select('*, profiles(*)')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('DEBUG getChatMessages error: $e');
      return [];
    }
  }

  /// Send a message in a chat room
  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    final messageResponse = await _client
        .from('messages')
        .insert({
          'chat_id': chatId,
          'sender_id': uid,
          'content': content,
          'type': type,
          'media_url': mediaUrl,
          'is_read': false,
        })
        .select('*, profiles(*)')
        .single();

    // Update chats table updated_at column
    await _client
        .from('chats')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);

    return MessageModel.fromJson(messageResponse);
  }

  /// Delete a message by ID
  Future<void> deleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }

  /// Mark all unread messages in a chat as read
  Future<void> markMessagesAsRead(String chatId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', uid)
        .eq('is_read', false);
  }

  /// Subscribe to Realtime WebSocket messages for a specific chat
  RealtimeChannel subscribeToMessages(
    String chatId,
    void Function(MessageModel message) onNewMessage,
  ) {
    final channel = _client.channel('public:messages:$chatId');

    Future<UserModel?> fetchProfile(String uid) => getProfileById(uid);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) async {
        final newRecord = payload.newRecord;
        final senderId = newRecord['sender_id'] as String;

        // Fetch sender profile details
        final senderProfile = await fetchProfile(senderId);

        final message = MessageModel.fromJson({
          ...newRecord,
          'profiles': senderProfile?.toJson(),
        });

        onNewMessage(message);
      },
    ).subscribe();

    return channel;
  }
}
