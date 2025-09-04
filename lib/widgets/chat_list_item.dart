import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/models/chat_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/controllers/auth_controller.dart';
import 'package:chat_app_flutter/controllers/home_controller.dart';

/// StatelessWidget that displays a single chat item in the chat list
/// Features user avatar, last message preview, unread badge, message status indicators,
/// and interactive actions like tap to open chat and long press for options
class ChatListItem extends StatelessWidget {
  final ChatModel chat;          // The chat data model
  final UserModel otherUser;     // The other participant in the chat
  final String lastMessageTime;  // Formatted time string for display
  final VoidCallback onTap;      // Callback when item is tapped

  const ChatListItem({
    super.key,
    required this.chat,
    required this.otherUser,
    required this.lastMessageTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HomeController homeController = Get.find<HomeController>();
    final currentUserId = authController.user?.uid ?? '';
    final unreadCount = chat.getUnreadCount(currentUserId);

    return Card(
      child: InkWell(
        onTap: () {
          // Mark chat as read when user opens it
          _markChatAsRead(homeController, currentUserId);
          onTap();
        },
        // Long press shows additional options menu
        onLongPress: () => _showChatOptions(context, homeController),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User avatar with online status indicator
              Stack(
                children: [
                  // Main profile picture with fallback to initials
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor,
                    child: otherUser.photoURL.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        otherUser.photoURL,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        // Fallback to initials if image fails to load
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      ),
                    )
                        : _buildDefaultAvatar(),
                  ),
                  // Online status indicator (green dot)
                  if (otherUser.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Chat content area with name, message preview, and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: user name and timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUser.displayName,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                              // Bold name when there are unread messages
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Show timestamp if available
                        if (lastMessageTime.isNotEmpty)
                          Text(
                            _formatLastMessageTime(chat.lastMessageTime),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                              // Highlight timestamp when unread messages exist
                              color: unreadCount > 0
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondaryColor,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Bottom row: message preview with status and unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Show message status icon for sent messages ONLY
                              if (chat.lastMessageSenderId == currentUserId &&
                                  chat.lastMessage != null &&
                                  chat.lastMessage!.isNotEmpty) ...[
                                Icon(
                                  _getMessageStatusIcon(currentUserId),
                                  size: 14,
                                  color: _getMessageStatusColor(currentUserId),
                                ),
                                const SizedBox(width: 4),
                              ],
                              // Last message preview text
                              Expanded(
                                child: Text(
                                  chat.lastMessage ?? 'No messages yet',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                    // Highlight message text when unread
                                    color: unreadCount > 0
                                        ? AppTheme.textPrimaryColor
                                        : AppTheme.textSecondaryColor,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Unread message count badge
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              // Show "99+" for counts over 99
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Marks the chat as read when user taps on it
  /// Resets the unread count for the current user
  /// @param homeController - Controller for managing chat operations
  /// @param currentUserId - ID of the current user
  void _markChatAsRead(HomeController homeController, String currentUserId) {
    try {
      // Force mark this chat as read
      homeController.markChatAsRead(chat.id, currentUserId);
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  /// Determines the appropriate status icon for sent messages
  /// Shows different icons based on whether the message has been seen
  /// @param currentUserId - ID of the current user
  /// @return IconData - The appropriate status icon
  IconData _getMessageStatusIcon(String currentUserId) {
    final otherUserId = chat.getOtherParticipant(currentUserId);

    // Enhanced logic for message status
    // Check if the other user has unread messages from us
    final otherUserUnreadCount = chat.getUnreadCount(otherUserId);

    if (otherUserUnreadCount == 0) {
      // If other user has no unread messages, it means they've seen our message
      return Icons.done_all; // Double checkmark for seen
    } else {
      // If other user has unread messages, our message is delivered but not seen
      return Icons.done; // Single checkmark for delivered
    }
  }

  /// Determines the appropriate color for message status icons
  /// Blue for seen messages, gray for delivered but not seen
  /// @param currentUserId - ID of the current user
  /// @return Color - The appropriate status color
  Color _getMessageStatusColor(String currentUserId) {
    final otherUserId = chat.getOtherParticipant(currentUserId);
    final otherUserUnreadCount = chat.getUnreadCount(otherUserId);

    if (otherUserUnreadCount == 0) {
      // Message has been seen
      return AppTheme.primaryColor; // Blue for seen
    } else {
      // Message is delivered but not seen
      return AppTheme.textSecondaryColor; // Gray for delivered
    }
  }

  /// Formats the last message timestamp for display
  /// Shows relative time for recent messages, exact time for today, dates for older
  /// @param time - The DateTime of the last message
  /// @return String - Formatted time string for display
  String _formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // Use 12-hour format for today's messages
      int hour = time.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString()}:${time.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Show full date for older messages
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  /// Shows a bottom sheet with chat options when user long presses
  /// Provides actions like delete chat and view user profile
  /// @param context - BuildContext for showing the bottom sheet
  /// @param homeController - Controller for handling chat actions
  void _showChatOptions(BuildContext context, HomeController homeController) {
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
            // Handle bar for visual feedback
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Delete chat option
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
              title: const Text('Delete Chat'),
              subtitle: const Text('This will only delete the chat for you'),
              onTap: () {
                Get.back();
                homeController.deleteChat(chat);
              },
            ),
            // View profile option
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppTheme.primaryColor,
              ),
              title: Text('View ${otherUser.displayName}\'s Profile'),
              onTap: () {
                Get.back();
                // TODO: Navigate to user profile
                Get.snackbar('Info', 'Profile view coming soon');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Builds the default avatar with user's initials
  /// Used when profile picture is unavailable or fails to load
  /// @return Widget - Text widget with user's initials
  Widget _buildDefaultAvatar() {
    return Text(
      otherUser.displayName.isNotEmpty
          ? otherUser.displayName[0].toUpperCase()
          : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
