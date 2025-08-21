import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/chat_model.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/friendship_model.dart';
import 'package:chat_app_flutter/models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users Collection
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

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

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

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

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

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

  // Friend Requests Collection
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

  // Friendships Collection
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

  // check if user is blocked
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

  // check if unfriend or not friends
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

  // Chats Collection
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

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update last seen: ${e.toString()}');
    }
  }

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

  Future<void> resetUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to reset unread count: ${e.toString()}');
    }
  }

  // Messages Collection
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

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

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

  // Notifications Collection
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

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

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

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

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