import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/chat_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/controllers/main_controller.dart';
import 'package:chat_app_flutter/widgets/message_bubble.dart';

/// StatefulWidget that provides the main chat interface for one-on-one conversations
/// Features real-time messaging, message editing/deletion, user presence indicators,
/// and proper controller lifecycle management with tagged GetX controllers
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  late final String chatId;              // Unique identifier for this chat session
  late final ChatController controller;   // Tagged controller for this specific chat
  final FocusNode _messageFocusNode = FocusNode(); // Focus management for message input

  @override
  void initState() {
    super.initState();

    // Get chatId from route arguments passed during navigation
    chatId = Get.arguments?['chatId'] ?? '';

    // Create controller with unique tag if it doesn't already exist
    // This prevents conflicts when multiple chat screens are open
    if (!Get.isRegistered<ChatController>(tag: chatId)) {
      Get.put<ChatController>(ChatController(), tag: chatId);
    }

    // Get the controller instance associated with this specific chat
    controller = Get.find<ChatController>(tag: chatId);

    // Register as observer to handle app lifecycle changes (foreground/background)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Clean up focus node to prevent memory leaks
    _messageFocusNode.dispose();
    // Unregister from app lifecycle observations
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Custom back button that cleans up the tagged controller
        leading: IconButton(
          onPressed: () {
            // Clean up controller with tag before navigating back
            // This prevents memory leaks and controller conflicts
            Get.delete<ChatController>(tag: chatId);
            Get.back();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        // Dynamic title showing other user's info and online status
        title: Obx(() {
          final otherUser = controller.otherUser;
          if (otherUser == null) return const Text('Chat');

          return Row(
            children: [
              // User avatar with fallback to initial letter
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child: otherUser.photoURL.isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    otherUser.photoURL,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    // Fallback to initial if image fails to load
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        otherUser.displayName.isNotEmpty
                            ? otherUser.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                )
                    : Text(
                  otherUser.displayName.isNotEmpty
                      ? otherUser.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User name and online status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Online/offline status with color coding
                    Text(
                      otherUser.isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: otherUser.isOnline
                            ? AppTheme.successColor    // Green for online
                            : AppTheme.textSecondaryColor,  // Gray for offline
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        // Action menu for chat operations
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  controller.deleteChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  title: Text('Delete Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list - takes up most of the screen space
          Expanded(
            child: Obx(() {
              // Show empty state when no messages exist
              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }

              // Build scrollable list of message bubbles
              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMyMessage = controller.isMyMessage(message);
                  // Show timestamp if this is the first message or if there's a 5+ minute gap
                  final showTime =
                      index == 0 ||
                          controller.messages[index - 1].timestamp
                              .difference(message.timestamp)
                              .inMinutes
                              .abs() >
                              5;

                  return MessageBubble(
                    message: message,
                    isMyMessage: isMyMessage,
                    showTime: showTime,
                    timeText: controller.formatMessageTime(message.timestamp),
                    // Only allow long press actions on user's own messages
                    onLongPress: isMyMessage
                        ? () => _showMessageOptions(message)
                        : null,
                  );
                },
              );
            }),
          ),
          // Message input area - fixed at bottom
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Handles app lifecycle state changes to manage chat presence
  /// Updates user's "last seen" status when app goes to background/foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // User returned to the app - mark as active in this chat
        controller.onChatResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      // User left the app - update last seen timestamp
        controller.onChatPaused();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Builds the empty state shown when no messages exist in the chat
  /// Encourages user to start the conversation with friendly messaging
  /// @return Widget - The empty state display
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chat icon in a circular container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.chat_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Encouraging headline text
            Text(
              'Start the conversation',
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Instructional subtext
            Text(
              'Send a message to get the chat started',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the message input area at the bottom of the screen
  /// Features text input field and send button with dynamic styling
  /// @return Widget - The message input interface
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field with rounded container styling
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        focusNode: _messageFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,  // Allow multi-line messages
                        textCapitalization: TextCapitalization.sentences,
                        // Send message when user presses Enter
                        onSubmitted: (_) => controller.sendMessage(fromEnterKey: true),
                        onTap: () {
                          // Auto-focus and scroll to bottom when tapping message input
                          controller.scrollController.animateTo(
                            controller.scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button with dynamic styling based on typing state
            Obx(
                  () => Container(
                decoration: BoxDecoration(
                  // Change color based on whether user is typing
                  color: controller.isTyping
                      ? AppTheme.primaryColor        // Active blue when typing
                      : AppTheme.borderColor,        // Inactive gray when empty
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  // Disable button when sending to prevent multiple submissions
                  onPressed: controller.isSending
                      ? null
                      : () => controller.sendMessage(),
                  icon: Icon(
                    Icons.send_rounded,
                    // Icon color matches button state
                    color: controller.isTyping
                        ? Colors.white                    // White on active button
                        : AppTheme.textSecondaryColor,    // Gray on inactive button
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows bottom sheet with message options (edit/delete) for user's own messages
  /// Only called when user long-presses their own message bubble
  /// @param message - The message object to show options for
  void _showMessageOptions(dynamic message) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit message option
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Edit Message'),
              onTap: () {
                Get.back(); // Close bottom sheet
                _showEditDialog(message);
              },
            ),
            // Delete message option with red styling
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete Message'),
              onTap: () {
                Get.back(); // Close bottom sheet
                _showDeleteDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Shows dialog for editing a message with current content pre-filled
  /// @param message - The message to edit
  void _showEditDialog(dynamic message) {
    // Pre-populate text field with current message content
    final editController = TextEditingController(text: message.content);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Enter new message'),
          maxLines: null, // Allow multi-line editing
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // Only save if there's actual content
              if (editController.text.trim().isNotEmpty) {
                controller.editMessage(message, editController.text.trim());
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog before deleting a message
  /// @param message - The message to delete
  void _showDeleteDialog(dynamic message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteMessage(message);
              Get.back();
            },
            // Red styling for destructive action
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
