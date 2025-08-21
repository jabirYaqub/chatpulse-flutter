import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';

// ChatController manages the chat functionality for a specific conversation.
// It handles fetching and sending messages, managing the UI state, and handling
// user interactions within the chat screen.
class ChatController extends GetxController {
  // Service and controller dependencies injected for a clean architecture.
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  // TextEditingController to manage the text input field for messages.
  final TextEditingController messageController = TextEditingController();
  // Uuid is used to generate unique IDs for each message.
  final Uuid _uuid = const Uuid();

  // Lazy initialization for the ScrollController to optimize performance.
  // The controller is only created when first accessed.
  ScrollController? _scrollController;
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  // Reactive state variables to manage the UI.
  final RxList<MessageModel> _messages = <MessageModel>[].obs; // Stream of messages for the chat.
  final RxBool _isLoading = false.obs; // Tracks global loading state.
  final RxBool _isSending = false.obs; // Tracks message sending state.
  final RxString _error = ''.obs; // Stores error messages.
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null); // The other user in the chat.
  final RxString _chatId = ''.obs; // The unique ID for this chat conversation.
  final RxBool _isTyping = false.obs; // Tracks if the user is typing.
  final RxBool _isChatActive = false.obs; // Tracks if the chat screen is currently visible.

  // Public getters to access the reactive state.
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  String get error => _error.value;
  UserModel? get otherUser => _otherUser.value;
  String get chatId => _chatId.value;
  bool get isTyping => _isTyping.value;

  /// Called when the controller is initialized.
  @override
  void onInit() {
    super.onInit();
    // Initialize the chat by processing arguments and loading messages.
    _initializeChat();
    // Add a listener to the message text controller to detect typing.
    messageController.addListener(_onMessageChanged);
  }

  /// Called when the widget is ready, after the first frame has been rendered.
  @override
  void onReady() {
    super.onReady();
    _isChatActive.value = true;
    // Mark messages as read immediately when the chat screen is fully loaded.
    _markMessagesAsRead();
    print('🟢 ChatController: Chat is now active, marking messages as read');
  }

  /// Called when the controller is closed and the widget is disposed.
  @override
  void onClose() {
    _isChatActive.value = false;
    // Mark messages as read one final time when leaving to ensure consistency.
    _markMessagesAsRead();
    print('🔴 ChatController: Chat is now inactive');
    // Dispose of the scroll controller to prevent memory leaks.
    _scrollController?.dispose();
    super.onClose();
  }

  /// Initializes the chat by retrieving data from GetX arguments.
  void _initializeChat() {
    final arguments = Get.arguments;
    if (arguments != null) {
      _chatId.value = arguments['chatId'] ?? '';
      _otherUser.value = arguments['otherUser'];
      _loadMessages();

      // Delayed marking as read to ensure the UI is fully built before fetching.
      Future.delayed(const Duration(milliseconds: 500), () {
        _markMessagesAsRead();
        print('⏰ ChatController: Delayed mark as read executed');
      });
    }
  }

  /// Binds the messages list to a Firestore stream to receive real-time updates.
  void _loadMessages() {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;

    if (currentUserId != null && otherUserId != null) {
      _messages.bindStream(
        _firestoreService.getMessagesStream(currentUserId, otherUserId),
      );

      // 'ever' listens for any change in the messages list.
      ever(_messages, (List<MessageModel> messageList) {
        if (_isChatActive.value) {
          // If the chat is active, mark new incoming messages as read.
          _markUnreadMessagesAsRead(messageList);
        }
        // Auto-scroll to the bottom of the list when a new message arrives.
        _scrollToBottom();
      });
    }
  }

  /// Animates the chat list to scroll to the bottom.
  void _scrollToBottom() {
    // `addPostFrameCallback` ensures the animation runs after the new message
    // has been rendered, preventing janky animations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Marks any unread messages from the other user as read.
  Future<void> _markUnreadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    try {
      // Filter for messages received by the current user that are not yet read.
      final unreadMessages = messageList
          .where(
            (message) =>
        message.receiverId == currentUserId &&
            !message.isRead &&
            message.senderId != currentUserId,
      )
          .toList();

      // Update each message in Firestore.
      for (var message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
      }

      // If there were unread messages, reset the unread count on the chat document.
      if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
        await _firestoreService.resetUnreadCount(_chatId.value, currentUserId);

        // Also update the unread count in the HomeController to refresh the UI on the home screen.
        try {
          final homeController = Get.find<HomeController>();
          await homeController.markChatAsRead(_chatId.value, currentUserId);
          print('✅ ChatController: Updated home controller chat list');
        } catch (e) {
          print('⚠️ ChatController: Home controller not found: $e');
        }
      }

      // Update the user's last seen timestamp.
      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
          _chatId.value,
          currentUserId,
        );
      }
    } catch (e) {
      print('❌ ChatController: Error marking messages as read: $e');
    }
  }

  /// Deletes the current chat for the logged-in user.
  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isEmpty) return;

      // Show a confirmation dialog before deleting.
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text(
            'Are you sure you want to delete this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        // Call the service to delete the chat.
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);

        // Clean up the controller from memory before navigating back.
        Get.delete<ChatController>(tag: _chatId.value);
        Get.back(); // Navigate back to the previous screen.
        Get.snackbar('Success', 'Chat deleted');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete chat: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Listener for the message text field to update the typing indicator.
  void _onMessageChanged() {
    _isTyping.value = messageController.text.isNotEmpty;
  }

  /// Sends a new message.
  Future<void> sendMessage({bool fromEnterKey = false}) async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();

    // Check for a valid sender, receiver, and content.
    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      return;
    }

    // Clear the input field immediately for a better user experience.
    messageController.clear();

    // Check for block or unfriend status before sending.
    if (await _firestoreService.isUserBlocked(currentUserId, otherUserId)) {
      Get.snackbar('Error', 'You cannot send messages to this user');
      return;
    }
    if (await _firestoreService.isUnfriended(currentUserId, otherUserId)) {
      Get.snackbar(
        'Error',
        'You cannot send messages to this user as you are not friends',
      );
      return;
    }

    try {
      _isSending.value = true;

      // Create a new MessageModel.
      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      // Send the message via FirestoreService.
      await _firestoreService.sendMessage(message);
      _isTyping.value = false;

      _scrollToBottom(); // Auto-scroll after sending.

      print('✅ ChatController: Message sent successfully');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to send message: ${e.toString()}');
      print('❌ ChatController: Error sending message: $e');
    } finally {
      _isSending.value = false;
    }
  }

  /// Marks all messages in the current chat as read for the current user.
  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      try {
        print('📖 ChatController: Marking messages as read for chat: ${_chatId.value}');

        // Reset unread count in Firestore.
        await _firestoreService.resetUnreadCount(_chatId.value, currentUserId);

        // Update home controller as well to reflect the change on the chat list page.
        try {
          final homeController = Get.find<HomeController>();
          await homeController.markChatAsRead(_chatId.value, currentUserId);
          print('✅ ChatController: Updated home controller from _markMessagesAsRead');
        } catch (e) {
          print('⚠️ ChatController: Home controller not found in _markMessagesAsRead: $e');
        }
      } catch (e) {
        print('❌ ChatController: Failed to mark messages as read: $e');
      }
    }
  }

  /// Handles actions when the chat screen is resumed (e.g., from background).
  void onChatResumed() {
    _isChatActive.value = true;
    _markUnreadMessagesAsRead(_messages);
    _markMessagesAsRead();
    print('🔄 ChatController: Chat resumed, marking as read');
  }

  /// Handles actions when the chat screen is paused (e.g., moving to background).
  void onChatPaused() {
    _isChatActive.value = false;
    print('⏸️ ChatController: Chat paused');
  }

  /// Deletes a specific message.
  Future<void> deleteMessage(MessageModel message) async {
    try {
      await _firestoreService.deleteMessage(message.id);
      Get.snackbar('Success', 'Message deleted');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete message: ${e.toString()}');
    }
  }

  /// Edits a specific message's content.
  Future<void> editMessage(MessageModel message, String newContent) async {
    try {
      await _firestoreService.editMessage(message.id, newContent);
      Get.snackbar('Success', 'Message edited');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to edit message: ${e.toString()}');
    }
  }

  /// Checks if a message was sent by the current user.
  bool isMyMessage(MessageModel message) {
    return message.senderId == _authController.user?.uid;
  }

  /// Formats a message's timestamp into a user-friendly string (e.g., 'Just now', '10:30 AM').
  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Format to 12-hour time (e.g., 10:30 AM).
      int hour = timestamp.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays < 7) {
      // Format to day of the week and 12-hour time (e.g., 'Mon 10:30 AM').
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      int hour = timestamp.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${days[timestamp.weekday - 1]} ${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
    } else {
      // Format to a full date for older messages.
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Clears the current error message.
  void clearError() {
    _error.value = '';
  }
}