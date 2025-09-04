import 'package:flutter/material.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatelessWidget that displays a single friend item in the friends list
/// Features user profile information, online status indicator, and action menu
/// Provides interactive options for messaging, removing, and blocking friends
class FriendListItem extends StatelessWidget {
  final UserModel friend;        // The friend's user model data
  final String lastSeenText;     // Formatted last seen time text
  final VoidCallback onTap;      // Callback when item is tapped (start chat)
  final VoidCallback onRemove;   // Callback for removing friend
  final VoidCallback onBlock;    // Callback for blocking friend

  const FriendListItem({
    super.key,
    required this.friend,
    required this.lastSeenText,
    required this.onTap,
    required this.onRemove,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap, // Primary action - start chat with friend
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Friend's profile picture with online status indicator
              Stack(
                children: [
                  // Main profile avatar with fallback to initials
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor,
                    child: friend.photoURL.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        friend.photoURL,
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
                  // Online status indicator (green dot when friend is online)
                  if (friend.isOnline)
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
              // Friend information section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Friend's display name
                    Text(
                      friend.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Friend's email address
                    Text(
                      friend.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Last seen status with dynamic styling based on online state
                    Text(
                      lastSeenText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        // Green color and bold text when online, gray when offline
                        color: friend.isOnline ? AppTheme.successColor : AppTheme.textSecondaryColor,
                        fontWeight: friend.isOnline ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions menu button with dropdown options
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'message':
                      onTap(); // Start chat with friend
                      break;
                    case 'remove':
                      onRemove(); // Remove friend from friends list
                      break;
                    case 'block':
                      onBlock(); // Block friend
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // Message friend option
                  const PopupMenuItem(
                    value: 'message',
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                      title: Text('Message'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  // Remove friend option (destructive action)
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove, color: AppTheme.errorColor),
                      title: Text('Remove Friend'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  // Block friend option (destructive action)
                  const PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      leading: Icon(Icons.block, color: AppTheme.errorColor),
                      title: Text('Block'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                // Three dots menu button
                child: const Icon(
                  Icons.more_vert,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the default avatar with friend's initials
  /// Used when profile picture is unavailable or fails to load
  /// @return Widget - Circular text widget with friend's initial
  Widget _buildDefaultAvatar() {
    return Text(
      friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
