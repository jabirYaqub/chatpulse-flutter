import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/chat_model.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/friendship_model.dart';
import 'package:chat_app_flutter/models/notification_model.dart';

/// Service class that handles all Firebase Firestore operations for the chat application
/// Manages users, friend requests, friendships, chats, messages, and notifications
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Users Collection ====================

  /// Creates a new user document in the Firestore 'users' collection
  /// @param user - UserModel object containing user data to be created
  /// @throws Exception if the user creation fails
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  /// Retrieves a user document by user ID from Firestore
  /// @param userId - The ID of the user to retrieve
  /// @return UserModel if user exists, null otherwise
  /// @throws Exception if the retrieval fails
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of user data for the specified user ID
  /// @param userId - The ID of the user to stream
  /// @return Stream<UserModel?> that emits user data changes in real-time
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  /// Updates an existing user document in Firestore
  /// @param user - UserModel object with updated user data
  /// @throws Exception if the update fails
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  /// Updates a user's online status and last seen timestamp
  /// Checks if the user document exists before attempting to update
  /// @param userId - The ID of the user whose status to update
  /// @param isOnline - Boolean indicating if the user is online
  /// @throws Exception if the update fails
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      // Check if document exists first
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        print(
          'Warning: User document $userId does not exist, cannot update online status',
        );
      }
    } catch (e) {
      print('Error updating user online status: ${e.toString()}');
      throw Exception('Failed to update user online status: ${e.toString()}');
    }
  }

  /// Deletes a user document from Firestore
  /// @param userId - The ID of the user to delete
  /// @throws Exception if the deletion fails
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of all users in the application
  /// @return Stream<List<UserModel>> that emits all users data in real-time
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList(),
    );
  }

  // ==================== Friend Requests Collection ====================

  /// Sends a friend request and creates a notification for the receiver
  /// Creates a predictable notification ID for easy management
  /// @param request - FriendRequestModel containing request details
  /// @throws Exception if sending the friend request fails
  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(request.id)
          .set(request.toMap());

      // Create notification for receiver with a predictable ID
      String notificationId =
          'friend_request_${request.senderId}_${request.receiverId}_${DateTime.now().millisecondsSinceEpoch}';

      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          title: 'New Friend Request',
          body: 'You have received a new friend request',
          type: NotificationType.friendRequest,
          data: {'senderId': request.senderId, 'requestId': request.id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to send friend request: ${e.toString()}');
    }
  }

  /// Cancels a pending friend request and removes associated notifications
  /// @param requestId - The ID of the friend request to cancel
  /// @throws Exception if cancellation fails
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      // Get the request details before deleting
      DocumentSnapshot requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );

        // Delete the friend request
        await _firestore.collection('friendRequests').doc(requestId).delete();

        // Remove the notification from receiver's notifications
        await deleteNotificationsByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception('Failed to cancel friend request: ${e.toString()}');
    }
  }

  /// Responds to a friend request with accept or decline status
  /// Creates friendship if accepted, sends appropriate notifications in both cases
  /// @param requestId - The ID of the friend request to respond to
  /// @param status - The response status (accepted/declined)
  /// @throws Exception if the response operation fails
  Future<void> respondToFriendRequest(
      String requestId,
      FriendRequestStatus status,
      ) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': status.name,
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Get the request details
      DocumentSnapshot requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();
      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );

        if (status == FriendRequestStatus.accepted) {
          // Create friendship
          await createFriendship(request.senderId, request.receiverId);

          // Create notification for sender
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Accepted',
              body: 'Your friend request has been accepted',
              type: NotificationType.friendRequestAccepted,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );

          // Remove the original friend request notification
          await _removeNotificationForCanceledRequest(
            request.receiverId,
            request.senderId,
          );
        } else if (status == FriendRequestStatus.declined) {
          // Create notification for sender
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Declined',
              body: 'Your friend request has been declined',
              type: NotificationType.friendRequestDeclined,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );

          // Remove the original friend request notification
          await _removeNotificationForCanceledRequest(
            request.receiverId,
            request.senderId,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to respond to friend request: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of pending friend requests received by a user
  /// Orders by creation date (most recent first)
  /// @param userId - The ID of the user to get friend requests for
  /// @return Stream<List<FriendRequestModel>> of pending friend requests
  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => FriendRequestModel.fromMap(doc.data()))
          .toList(),
    );
  }

  /// Creates a real-time stream of friend requests sent by a user
  /// Orders by creation date (most recent first)
  /// @param userId - The ID of the user who sent the requests
  /// @return Stream<List<FriendRequestModel>> of sent friend requests
  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => FriendRequestModel.fromMap(doc.data()))
          .toList(),
    );
  }

  /// Retrieves a specific pending friend request between two users
  /// @param senderId - The ID of the user who sent the request
  /// @param receiverId - The ID of the user who received the request
  /// @return FriendRequestModel if exists, null otherwise
  /// @throws Exception if the retrieval fails
  Future<FriendRequestModel?> getFriendRequest(
      String senderId,
      String receiverId,
      ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (query.docs.isNotEmpty) {
        return FriendRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friend request: ${e.toString()}');
    }
  }

  // ==================== Friendships Collection ====================

  /// Creates a friendship between two users with a deterministic ID
  /// Sorts user IDs to ensure consistent friendship document naming
  /// @param user1Id - First user's ID
  /// @param user2Id - Second user's ID
  /// @throws Exception if friendship creation fails
  Future<void> createFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      FriendshipModel friendship = FriendshipModel(
        id: friendshipId,
        user1Id: userIds[0],
        user2Id: userIds[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .set(friendship.toMap());
    } catch (e) {
      throw Exception('Failed to create friendship: ${e.toString()}');
    }
  }

  /// Removes a friendship between two users and notifies both parties
  /// @param user1Id - First user's ID
  /// @param user2Id - Second user's ID
  /// @throws Exception if friendship removal fails
  Future<void> removeFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';
      await _firestore.collection('friendships').doc(friendshipId).delete();

      // Create notifications for both users
      await createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user2Id,
          title: 'Friend Removed',
          body: 'You are no longer friends',
          type: NotificationType.friendRemoved,
          data: {'userId': user1Id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to remove friendship: ${e.toString()}');
    }
  }

  /// Blocks a user by updating the friendship document
  /// Marks the friendship as blocked and records who initiated the block
  /// @param blockerId - The ID of the user initiating the block
  /// @param blockedId - The ID of the user being blocked
  /// @throws Exception if blocking fails
  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  /// Unblocks a previously blocked user
  /// @param user1Id - First user's ID
  /// @param user2Id - Second user's ID
  /// @throws Exception if unblocking fails
  Future<void> unblockUser(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of all friendships for a user
  /// Queries both user1Id and user2Id fields since the user could be in either position
  /// Filters out blocked friendships
  /// @param userId - The ID of the user to get friends for
  /// @return Stream<List<FriendshipModel>> of active friendships
  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot1) async {
      QuerySnapshot snapshot2 = await _firestore
          .collection('friendships')
          .where('user2Id', isEqualTo: userId)
          .get();

      List<FriendshipModel> friendships = [];

      for (var doc in snapshot1.docs) {
        friendships.add(
          FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
        );
      }

      for (var doc in snapshot2.docs) {
        friendships.add(
          FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
        );
      }

      return friendships.where((f) => !f.isBlocked).toList();
    });
  }

  /// Retrieves a specific friendship between two users
  /// @param user1Id - First user's ID
  /// @param user2Id - Second user's ID
  /// @return FriendshipModel if exists, null otherwise
  /// @throws Exception if the retrieval fails
  Future<FriendshipModel?> getFriendship(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';
      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (doc.exists) {
        return FriendshipModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friendship: ${e.toString()}');
    }
  }

  /// Checks if a user is blocked by another user
  /// @param userId - The ID of the current user
  /// @param otherUserId - The ID of the other user to check
  /// @return true if blocked, false otherwise
  /// @throws Exception if the check fails
  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';
      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check if user is blocked: ${e.toString()}');
    }
  }

  /// Checks if two users are unfriended (no friendship exists)
  /// @param userId - The ID of the current user
  /// @param otherUserId - The ID of the other user to check
  /// @return true if unfriended or never were friends, false if friendship exists
  /// @throws Exception if the check fails
  Future<bool> isUnfriended(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendshipId = '${userIds[0]}_${userIds[1]}';
      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      return !doc.exists || (doc.exists && doc.data() == null);
    } catch (e) {
      throw Exception(
        'Failed to check if users are unfriended: ${e.toString()}',
      );
    }
  }

  // ==================== Chats Collection ====================

  /// Creates a new chat or retrieves an existing one between two users
  /// Uses deterministic chat ID based on sorted user IDs
  /// Restores deleted chats if they exist
  /// @param userId1 - First user's ID
  /// @param userId2 - Second user's ID
  /// @return String chat ID
  /// @throws Exception if chat creation/retrieval fails
  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      List<String> participants = [userId1, userId2];
      participants.sort();

      String chatId = '${participants[0]}_${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        ChatModel newChat = ChatModel(
          id: chatId,
          participants: participants,
          unreadCount: {userId1: 0, userId2: 0},
          deletedBy: {userId1: false, userId2: false},
          deletedAt: {userId1: null, userId2: null},
          lastSeenBy: {userId1: DateTime.now(), userId2: DateTime.now()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await chatRef.set(newChat.toMap());
      } else {
        // If chat exists but was deleted by current user, restore it
        ChatModel existingChat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        if (existingChat.isDeletedBy(userId1)) {
          await restoreChatForUser(chatId, userId1);
        }
        if (existingChat.isDeletedBy(userId2)) {
          await restoreChatForUser(chatId, userId2);
        }
      }

      return chatId;
    } catch (e) {
      throw Exception('Failed to create or get chat: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of chats for a specific user
  /// Orders by last update (most recent first) and filters out deleted chats
  /// @param userId - The ID of the user to get chats for
  /// @return Stream<List<ChatModel>> of user's active chats
  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .where(
            (chat) => !chat.isDeletedBy(userId),
      ) // Filter out deleted chats
          .toList(),
    );
  }

  /// Updates the last message information for a chat
  /// @param chatId - The ID of the chat to update
  /// @param message - The message object containing the latest message data
  /// @throws Exception if the update fails
  Future<void> updateChatLastMessage(
      String chatId,
      MessageModel message,
      ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update chat last message: ${e.toString()}');
    }
  }

  /// Updates when a user last saw the chat (for read receipts)
  /// @param chatId - The ID of the chat
  /// @param userId - The ID of the user who viewed the chat
  /// @throws Exception if the update fails
  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update last seen: ${e.toString()}');
    }
  }

  /// Marks a chat as deleted for a specific user (soft delete)
  /// The chat remains visible to the other participant
  /// @param chatId - The ID of the chat to delete
  /// @param userId - The ID of the user deleting the chat
  /// @throws Exception if the deletion fails
  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  /// Restores a previously deleted chat for a user
  /// @param chatId - The ID of the chat to restore
  /// @param userId - The ID of the user restoring the chat
  /// @throws Exception if the restoration fails
  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': false,
        // Keep the deletedAt timestamp for filtering old messages
      });
    } catch (e) {
      throw Exception('Failed to restore chat: ${e.toString()}');
    }
  }

  /// Updates the unread message count for a specific user in a chat
  /// @param chatId - The ID of the chat
  /// @param userId - The ID of the user
  /// @param count - The new unread count
  /// @throws Exception if the update fails
  Future<void> updateUnreadCount(
      String chatId,
      String userId,
      int count,
      ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': count,
      });
    } catch (e) {
      throw Exception('Failed to update unread count: ${e.toString()}');
    }
  }

  /// Resets the unread message count to zero for a user in a chat
  /// @param chatId - The ID of the chat
  /// @param userId - The ID of the user
  /// @throws Exception if the reset fails
  Future<void> resetUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to reset unread count: ${e.toString()}');
    }
  }

  // ==================== Messages Collection ====================

  /// Sends a message and updates related chat information
  /// Creates or gets the chat, updates last message, last seen, and unread count
  /// @param message - The MessageModel to send
  /// @throws Exception if sending fails
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      // Update chat last message
      String chatId = await createOrGetChat(
        message.senderId,
        message.receiverId,
      );
      await updateChatLastMessage(chatId, message);

      // Update sender's last seen
      await updateUserLastSeen(chatId, message.senderId);

      // Update unread count for receiver
      DocumentSnapshot chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();
      if (chatDoc.exists) {
        ChatModel chat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        int currentUnread = chat.getUnreadCount(message.receiverId);
        await updateUnreadCount(chatId, message.receiverId, currentUnread + 1);
      }
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of messages between two users
  /// Filters messages based on chat deletion timestamps for the current user
  /// @param userId1 - First user's ID (usually current user)
  /// @param userId2 - Second user's ID
  /// @return Stream<List<MessageModel>> of messages sorted by timestamp
  Stream<List<MessageModel>> getMessagesStream(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .snapshots()
        .asyncMap((snapshot) async {
      // Get chat info to check deletion timestamps
      List<String> participants = [userId1, userId2];
      participants.sort();
      String chatId = '${participants[0]}_${participants[1]}';

      DocumentSnapshot chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();
      ChatModel? chat;
      if (chatDoc.exists) {
        chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
      }

      List<MessageModel> messages = [];
      for (var doc in snapshot.docs) {
        MessageModel message = MessageModel.fromMap(doc.data());
        if ((message.senderId == userId1 &&
            message.receiverId == userId2) ||
            (message.senderId == userId2 &&
                message.receiverId == userId1)) {
          // Filter messages based on deletion timestamp for current user (userId1)
          bool includeMessage = true;
          if (chat != null) {
            DateTime? currentUserDeletedAt = chat.getDeletedAt(userId1);
            if (currentUserDeletedAt != null &&
                message.timestamp.isBefore(currentUserDeletedAt)) {
              includeMessage = false;
            }
          }

          if (includeMessage) {
            messages.add(message);
          }
        }
      }
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Marks a specific message as read
  /// @param messageId - The ID of the message to mark as read
  /// @throws Exception if marking as read fails
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  /// Soft deletes a message by marking it as deleted and replacing content
  /// @param messageId - The ID of the message to delete
  /// @throws Exception if deletion fails
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
        'content': 'This message was deleted',
      });
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  /// Edits a message with new content and marks it as edited
  /// @param messageId - The ID of the message to edit
  /// @param newContent - The new content for the message
  /// @throws Exception if editing fails
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  // ==================== Notifications Collection ====================

  /// Creates a new notification document in Firestore
  /// @param notification - The NotificationModel to create
  /// @throws Exception if creation fails
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  /// Creates a real-time stream of notifications for a specific user
  /// Orders by creation date (most recent first)
  /// @param userId - The ID of the user to get notifications for
  /// @return Stream<List<NotificationModel>> of user's notifications
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList(),
    );
  }

  /// Marks a specific notification as read
  /// @param notificationId - The ID of the notification to mark as read
  /// @throws Exception if marking as read fails
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  /// Marks all unread notifications as read for a specific user
  /// Uses batch operations for efficiency
  /// @param userId - The ID of the user whose notifications to mark as read
  /// @throws Exception if batch operation fails
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        'Failed to mark all notifications as read: ${e.toString()}',
      );
    }
  }

  /// Deletes a specific notification
  /// @param notificationId - The ID of the notification to delete
  /// @throws Exception if deletion fails
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  /// Deletes notifications of a specific type related to a specific user
  /// Used for cleaning up notifications when friend requests are canceled/responded to
  /// @param userId - The user whose notifications to search
  /// @param type - The type of notification to delete
  /// @param relatedUserId - The ID of the related user (sender/receiver)
  Future<void> deleteNotificationsByTypeAndUser(
      String userId,
      NotificationType type,
      String relatedUserId,
      ) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in notifications.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Check if notification is related to the specific user
        if (data['data'] != null &&
            (data['data']['senderId'] == relatedUserId ||
                data['data']['userId'] == relatedUserId)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting notifications: $e');
    }
  }

  /// Private helper method to remove friend request notifications
  /// Called when friend requests are canceled or responded to
  /// @param receiverId - The ID of the user who received the original request
  /// @param senderId - The ID of the user who sent the original request
  Future<void> _removeNotificationForCanceledRequest(
      String receiverId,
      String senderId,
      ) async {
    try {
      await deleteNotificationsByTypeAndUser(
        receiverId,
        NotificationType.friendRequest,
        senderId,
      );
    } catch (e) {
      print('Error removing notification for canceled request: $e');
    }
  }
}
