import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/services/firestore_service.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';

/// ChatController manages the chat functionality for a specific conversation.
/// It handles fetching and sending messages, managing the UI state, and handling
/// user interactions within the chat screen.
///
/// This controller is responsible for:
/// - Real-time message streaming and display
/// - Message sending, editing, and deletion
/// - Read status management and unread count tracking
/// - Auto-scrolling to new messages
/// - Typing indicators and chat activity status
/// - User blocking and friendship validation
/// - Chat deletion and cleanup operations
/// - Integration with HomeController for chat list updates
class ChatController extends GetxController {

  // ==================== DEPENDENCIES ====================

  /// Service and controller dependencies injected for a clean architecture.
  /// These provide data access and authentication functionality.

  /// Service for Firestore database operations (messages, chats, users)
  final FirestoreService _firestoreService = FirestoreService();

  /// Authentication controller to access current user information
  final AuthController _authController = Get.find<AuthController>();

  /// TextEditingController to manage the text input field for messages.
  /// Allows reading, clearing, and listening to changes in the message input.
  final TextEditingController messageController = TextEditingController();

  /// Uuid is used to generate unique IDs for each message to ensure no conflicts.
  final Uuid _uuid = const Uuid();

  // ==================== SCROLL CONTROLLER MANAGEMENT ====================

  /// Lazy initialization for the ScrollController to optimize performance.
  /// The controller is only created when first accessed to save memory.
  ScrollController? _scrollController;

  /// Getter that creates ScrollController on first access (lazy initialization).
  /// This controller manages scrolling behavior in the chat message list.
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  // ==================== REACTIVE STATE VARIABLES ====================

  /// Reactive state variables to manage the UI using GetX observables.
  /// These automatically trigger UI updates when values change.

  /// Stream of messages for the chat, automatically updated from Firestore
  final RxList<MessageModel> _messages = <MessageModel>[].obs;

  /// Tracks global loading state for operations like chat deletion
  final RxBool _isLoading = false.obs;

  /// Tracks message sending state to show progress indicators
  final RxBool _isSending = false.obs;

  /// Stores error messages for display to user
  final RxString _error = ''.obs;

  /// The other user in the chat (not the current user)
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);

  /// The unique ID for this chat conversation
  final RxString _chatId = ''.obs;

  /// Tracks if the current user is typing (for typing indicators)
  final RxBool _isTyping = false.obs;

  /// Tracks if the chat screen is currently visible and active
  final RxBool _isChatActive = false.obs;

  // ==================== PUBLIC GETTERS ====================

  /// Public getters to access the reactive state without exposing Rx objects.
  /// These provide a clean API for UI components to access controller state.

  /// Returns the list of messages in this chat
  List<MessageModel> get messages => _messages;

  /// Returns true if any loading operation is in progress
  bool get isLoading => _isLoading.value;

  /// Returns true if a message is currently being sent
  bool get isSending => _isSending.value;

  /// Returns current error message or empty string if no error
  String get error => _error.value;

  /// Returns the other user's data or null if not loaded
  UserModel? get otherUser => _otherUser.value;

  /// Returns the chat ID for this conversation
  String get chatId => _chatId.value;

  /// Returns true if the current user is typing
  bool get isTyping => _isTyping.value;

  // ==================== LIFECYCLE METHODS ====================

  /// Called when the controller is initialized.
  /// Sets up the initial state and listeners for the chat.
  @override
  void onInit() {
    super.onInit();
    // Initialize the chat by processing arguments and loading messages.
    _initializeChat();
    // Add a listener to the message text controller to detect typing.
    // This enables real-time typing indicators in the UI.
    messageController.addListener(_onMessageChanged);
  }

  /// Called when the widget is ready, after the first frame has been rendered.
  /// This ensures the UI is fully loaded before performing operations.
  @override
  void onReady() {
    super.onReady();
    // Mark the chat as active for read status management
    _isChatActive.value = true;
    // Mark messages as read immediately when the chat screen is fully loaded.
    _markMessagesAsRead();
    print('🟢 ChatController: Chat is now active, marking messages as read');
  }

  /// Called when the controller is closed and the widget is disposed.
  /// Performs cleanup operations to prevent memory leaks and update state.
  @override
  void onClose() {
    // Mark chat as inactive
    _isChatActive.value = false;
    // Mark messages as read one final time when leaving to ensure consistency.
    _markMessagesAsRead();
    print('🔴 ChatController: Chat is now inactive');
    // Dispose of the scroll controller to prevent memory leaks.
    _scrollController?.dispose();
    super.onClose();
  }

  // ==================== CHAT INITIALIZATION ====================

  /// Initializes the chat by retrieving data from GetX arguments.
  /// This method extracts chat ID and other user data passed from the previous screen.
  void _initializeChat() {
    // Get arguments passed from the previous screen via Get.toNamed()
    final arguments = Get.arguments;
    if (arguments != null) {
      // Extract chat ID and other user data from arguments
      _chatId.value = arguments['chatId'] ?? '';
      _otherUser.value = arguments['otherUser'];
      // Start loading messages from Firestore
      _loadMessages();

      // Delayed marking as read to ensure the UI is fully built before fetching.
      // This prevents race conditions between UI building and data operations.
      Future.delayed(const Duration(milliseconds: 500), () {
        _markMessagesAsRead();
        print('⏰ ChatController: Delayed mark as read executed');
      });
    }
  }

  /// Binds the messages list to a Firestore stream to receive real-time updates.
  /// This creates a reactive connection where new messages automatically appear in the UI.
  void _loadMessages() {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;

    // Ensure both users are valid before setting up the stream
    if (currentUserId != null && otherUserId != null) {
      // Bind the reactive list to a Firestore stream
      // This automatically updates _messages when Firestore data changes
      _messages.bindStream(
        _firestoreService.getMessagesStream(currentUserId, otherUserId),
      );

      // 'ever' listens for any change in the messages list.
      // This triggers when new messages arrive or existing messages are updated.
      ever(_messages, (List<MessageModel> messageList) {
        if (_isChatActive.value) {
          // If the chat is active, mark new incoming messages as read.
          // This ensures messages are marked as read only when user is actively viewing chat.
          _markUnreadMessagesAsRead(messageList);
        }
        // Auto-scroll to the bottom of the list when a new message arrives.
        // This keeps the most recent message visible to the user.
        _scrollToBottom();
      });
    }
  }

  // ==================== SCROLL MANAGEMENT ====================

  /// Animates the chat list to scroll to the bottom.
  /// This ensures the most recent message is visible after sending or receiving.
  void _scrollToBottom() {
    // `addPostFrameCallback` ensures the animation runs after the new message
    // has been rendered, preventing janky animations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if scroll controller exists and is attached to a scroll view
      if (_scrollController != null && _scrollController!.hasClients) {
        // Animate to the maximum scroll position (bottom of the list)
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== MESSAGE READ STATUS MANAGEMENT ====================

  /// Marks any unread messages from the other user as read.
  /// This method is called when the chat is active and new messages arrive.
  Future<void> _markUnreadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    try {
      // Filter for messages received by the current user that are not yet read.
      // Excludes messages sent by the current user to avoid marking own messages as read.
      final unreadMessages = messageList
          .where(
            (message) =>
        message.receiverId == currentUserId &&
            !message.isRead &&
            message.senderId != currentUserId,
      )
          .toList();

      // Update each unread message in Firestore to mark as read
      for (var message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
      }

      // If there were unread messages, reset the unread count on the chat document.
      if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
        // Reset the unread counter for this chat
        await _firestoreService.resetUnreadCount(_chatId.value, currentUserId);

        // Also update the unread count in the HomeController to refresh the UI on the home screen.
        // This ensures the chat list shows updated read status immediately.
        try {
          final homeController = Get.find<HomeController>();
          await homeController.markChatAsRead(_chatId.value, currentUserId);
          print('✅ ChatController: Updated home controller chat list');
        } catch (e) {
          // HomeController might not be initialized, which is not a critical error
          print('⚠️ ChatController: Home controller not found: $e');
        }
      }

      // Update the user's last seen timestamp to track activity
      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
          _chatId.value,
          currentUserId,
        );
      }
    } catch (e) {
      // Log error but don't crash the app - read status is not critical
      print('❌ ChatController: Error marking messages as read: $e');
    }
  }

  /// Marks all messages in the current chat as read for the current user.
  /// This is called when the chat screen becomes active or when leaving the chat.
  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      try {
        print('📖 ChatController: Marking messages as read for chat: ${_chatId.value}');

        // Reset unread count in Firestore for this chat
        await _firestoreService.resetUnreadCount(_chatId.value, currentUserId);

        // Update home controller as well to reflect the change on the chat list page.
        // This ensures consistency between chat screen and chat list.
        try {
          final homeController = Get.find<HomeController>();
          await homeController.markChatAsRead(_chatId.value, currentUserId);
          print('✅ ChatController: Updated home controller from _markMessagesAsRead');
        } catch (e) {
          // HomeController might not be available, which is acceptable
          print('⚠️ ChatController: Home controller not found in _markMessagesAsRead: $e');
        }
      } catch (e) {
        // Log error but continue - read status updates are not critical for core functionality
        print('❌ ChatController: Failed to mark messages as read: $e');
      }
    }
  }

  // ==================== CHAT LIFECYCLE MANAGEMENT ====================

  /// Handles actions when the chat screen is resumed (e.g., from background).
  /// This ensures read status is properly updated when user returns to the chat.
  void onChatResumed() {
    _isChatActive.value = true;
    // Mark any unread messages as read
    _markUnreadMessagesAsRead(_messages);
    // Update overall chat read status
    _markMessagesAsRead();
    print('🔄 ChatController: Chat resumed, marking as read');
  }

  /// Handles actions when the chat screen is paused (e.g., moving to background).
  /// This prevents messages from being marked as read when user is not actively viewing.
  void onChatPaused() {
    _isChatActive.value = false;
    print('⏸️ ChatController: Chat paused');
  }

  // ==================== CHAT DELETION ====================

  /// Deletes the current chat for the logged-in user.
  /// This removes the chat from the user's chat list but doesn't affect the other user.
  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isEmpty) return;

      // Show a confirmation dialog before deleting to prevent accidental deletions.
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text(
            'Are you sure you want to delete this chat? This action cannot be undone.',
          ),
          actions: [
            // Cancel button - returns false
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            // Delete button - returns true and styled in red to indicate danger
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      // Proceed with deletion only if user confirmed
      if (result == true) {
        _isLoading.value = true;
        // Call the service to delete the chat from Firestore
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);

        // Clean up the controller from memory before navigating back.
        // Using tag ensures we delete the correct controller instance.
        Get.delete<ChatController>(tag: _chatId.value);
        Get.back(); // Navigate back to the previous screen.
        Get.snackbar('Success', 'Chat deleted');
      }
    } catch (e) {
      // Handle deletion errors gracefully
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete chat: ${e.toString()}');
    } finally {
      // Always reset loading state
      _isLoading.value = false;
    }
  }

  // ==================== MESSAGE INPUT HANDLING ====================

  /// Listener for the message text field to update the typing indicator.
  /// This is called automatically whenever the user types or deletes text.
  void _onMessageChanged() {
    // Set typing indicator based on whether there's text in the input field
    _isTyping.value = messageController.text.isNotEmpty;
  }

  /// Sends a new message after validation and security checks.
  /// Handles the complete message sending flow including validation and error handling.
  Future<void> sendMessage({bool fromEnterKey = false}) async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();

    // Check for a valid sender, receiver, and content.
    // Return early if any validation fails.
    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      return;
    }

    // Clear the input field immediately for a better user experience.
    // This provides immediate feedback that the message is being processed.
    messageController.clear();

    // Check for block or unfriend status before sending.
    // This prevents messages to blocked or unfriended users.
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
      // Set sending state to show progress indicators
      _isSending.value = true;

      // Create a new MessageModel with all required data.
      final message = MessageModel(
        id: _uuid.v4(), // Generate unique ID
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text, // Currently only supporting text messages
        timestamp: DateTime.now(),
      );

      // Send the message via FirestoreService to the database
      await _firestoreService.sendMessage(message);

      // Clear typing indicator since message has been sent
      _isTyping.value = false;

      // Auto-scroll to show the new message
      _scrollToBottom();

      print('✅ ChatController: Message sent successfully');
    } catch (e) {
      // Handle sending errors and provide user feedback
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to send message: ${e.toString()}');
      print('❌ ChatController: Error sending message: $e');
    } finally {
      // Always reset sending state
      _isSending.value = false;
    }
  }

  // ==================== MESSAGE MANAGEMENT ====================

  /// Deletes a specific message from the chat.
  /// This removes the message for all users in the conversation.
  Future<void> deleteMessage(MessageModel message) async {
    try {
      // Call Firestore service to delete the message
      await _firestoreService.deleteMessage(message.id);
      Get.snackbar('Success', 'Message deleted');
    } catch (e) {
      // Handle deletion errors
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to delete message: ${e.toString()}');
    }
  }

  /// Edits a specific message's content.
  /// Updates the message content in Firestore for all users.
  Future<void> editMessage(MessageModel message, String newContent) async {
    try {
      // Call Firestore service to update the message content
      await _firestoreService.editMessage(message.id, newContent);
      Get.snackbar('Success', 'Message edited');
    } catch (e) {
      // Handle editing errors
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to edit message: ${e.toString()}');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Checks if a message was sent by the current user.
  /// Used for UI styling and message positioning (left vs right alignment).
  bool isMyMessage(MessageModel message) {
    return message.senderId == _authController.user?.uid;
  }

  /// Formats a message's timestamp into a user-friendly string (e.g., 'Just now', '10:30 AM').
  /// Provides different formatting based on how recent the message is.
  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      // Very recent messages
      return 'Just now';
    } else if (difference.inHours < 1) {
      // Messages within the last hour
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Messages from today - format to 12-hour time (e.g., 10:30 AM).
      int hour = timestamp.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays < 7) {
      // Messages from this week - format to day of the week and 12-hour time (e.g., 'Mon 10:30 AM').
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      int hour = timestamp.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${days[timestamp.weekday - 1]} ${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
    } else {
      // Older messages - format to a full date for clarity.
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Clears the current error message.
  /// Useful for resetting error state when user dismisses errors or starts new operations.
  void clearError() {
    _error.value = '';
  }
}
