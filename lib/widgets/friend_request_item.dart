import 'package:flutter/material.dart';
import 'package:chat_app_flutter/models/friend_request_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatelessWidget that displays a single friend request item
/// Features different layouts for received vs sent requests, with interactive buttons
/// for received requests and status indicators for sent requests
class FriendRequestItem extends StatelessWidget {
  final FriendRequestModel request;  // The friend request data
  final UserModel user;              // The other user involved in the request
  final String timeText;             // Formatted time string for display
  final bool isReceived;             // Whether this is a received or sent request
  final VoidCallback? onAccept;      // Callback for accepting request (received only)
  final VoidCallback? onDecline;     // Callback for declining request (received only)
  final String? statusText;          // Status text for sent requests
  final Color? statusColor;          // Status color for sent requests

  const FriendRequestItem({
    super.key,
    required this.request,
    required this.user,
    required this.timeText,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
    this.statusText,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main content row with user info
            Row(
              children: [
                // User profile picture with fallback to initials
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: user.photoURL.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      user.photoURL,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      // Fallback to initials if image fails to load
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                      : _buildDefaultAvatar(),
                ),
                const SizedBox(width: 12),
                // User information section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: user name and timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Request timestamp
                          Text(
                            timeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // User's email address
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Optional message attached to the friend request
                      if (request.message?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.message!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Action buttons for received pending requests
            if (isReceived && request.status == FriendRequestStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Decline button with error styling
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept button with success styling
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              // Status indicator for sent requests
            ] else if (!isReceived && statusText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor ?? AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status icon based on request status
                    Icon(
                      _getStatusIcon(request.status),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    // Status text (e.g., "Pending", "Accepted", "Declined")
                    Text(
                      statusText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the default avatar with user's initials
  /// Used when profile picture is unavailable or fails to load
  /// @return Widget - Circular text widget with user's initial
  Widget _buildDefaultAvatar() {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Returns the appropriate icon for each friend request status
  /// Used in the status indicator for sent requests
  /// @param status - The current status of the friend request
  /// @return IconData - The corresponding icon for the status
  IconData _getStatusIcon(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return Icons.access_time;    // Clock icon for pending
      case FriendRequestStatus.accepted:
        return Icons.check_circle;   // Check circle for accepted
      case FriendRequestStatus.declined:
        return Icons.cancel;         // Cancel icon for declined
    }
  }
}
