import 'package:flutter/material.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

/// StatelessWidget that displays a single message bubble in a chat conversation
/// Features different styling for sent vs received messages, read receipts, edit indicators,
/// deleted message states, and optional timestamp displays with long press interactions
class MessageBubble extends StatelessWidget {
  final MessageModel message;       // The message data to display
  final bool isMyMessage;          // Whether this message was sent by current user
  final bool showTime;             // Whether to show timestamp separator above bubble
  final String timeText;           // Formatted timestamp text for separator
  final VoidCallback? onLongPress; // Optional callback for long press actions

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.showTime,
    required this.timeText,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Optional timestamp separator shown above message groups
        if (showTime) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 4), // Smaller spacing between consecutive messages

        // Main message bubble row
        Row(
          // Align messages to right for sent, left for received
          mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Left padding for received messages
            if (!isMyMessage) ...[
              const SizedBox(width: 8),
            ],
            // Flexible wrapper to prevent overflow while maintaining bubble sizing
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress, // Enable long press actions (edit/delete)
                child: Container(
                  // Limit bubble width to 75% of screen width
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    // Different colors for deleted, sent, and received messages
                    color: message.isDeleted
                        ? Colors.grey[100]           // Light gray for deleted messages
                        : isMyMessage
                        ? AppTheme.primaryColor      // Primary color for sent messages
                        : AppTheme.cardColor,        // Card color for received messages
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      // Different bottom corners create chat bubble tail effect
                      bottomLeft: isMyMessage ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMyMessage ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    // Border only for received messages (not sent or deleted)
                    border: isMyMessage || message.isDeleted
                        ? null
                        : Border.all(color: AppTheme.borderColor, width: 1),
                    // Subtle shadow for depth
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content area - different display for deleted vs normal messages
                      if (message.isDeleted) ...[
                        // Deleted message indicator
                        Row(
                          children: [
                            Icon(
                              Icons.block,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'This message was deleted',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Normal message content
                        Text(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            // White text on sent messages, dark on received
                            color: isMyMessage ? Colors.white : AppTheme.textPrimaryColor,
                          ),
                        ),
                        // Edit indicator for modified messages
                        if (message.isEdited) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Edited',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isMyMessage
                                  ? Colors.white.withOpacity(0.7)
                                  : AppTheme.textSecondaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 4),
                      // Message metadata row (time and read receipt)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Message timestamp in 12-hour format
                          Text(
                            _formatTime(message.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: message.isDeleted
                                  ? Colors.grey[500]
                                  : isMyMessage
                                  ? Colors.white.withOpacity(0.7)
                                  : AppTheme.textSecondaryColor,
                              fontSize: 11,
                            ),
                          ),
                          // Read receipt indicators for sent messages only
                          if (isMyMessage && !message.isDeleted) ...[
                            const SizedBox(width: 4),
                            Icon(
                              // Double checkmark for read, single for delivered
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead
                                  ? AppTheme.successColor      // Green when read
                                  : Colors.white.withOpacity(0.7), // Transparent when delivered
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Right padding for sent messages
            if (isMyMessage) ...[
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  /// Formats message timestamp to 12-hour format with AM/PM
  /// Used for displaying time within each message bubble
  /// @param timestamp - The DateTime of the message
  /// @return String - Formatted time string (e.g., "2:30 PM")
  String _formatTime(DateTime timestamp) {
    int hour = timestamp.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    // Convert to 12-hour format
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }
}
