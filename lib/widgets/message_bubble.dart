import 'package:flutter/material.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final bool showTime;
  final String timeText;
  final VoidCallback? onLongPress;

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
          const SizedBox(height: 4),
        Row(
          mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMyMessage) ...[
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isDeleted
                        ? Colors.grey[100]
                        : isMyMessage
                        ? AppTheme.primaryColor
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMyMessage ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isMyMessage ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: isMyMessage || message.isDeleted
                        ? null
                        : Border.all(color: AppTheme.borderColor, width: 1),
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
                      if (message.isDeleted) ...[
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
                        Text(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isMyMessage ? Colors.white : AppTheme.textPrimaryColor,
                          ),
                        ),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          if (isMyMessage && !message.isDeleted) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead
                                  ? AppTheme.successColor
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isMyMessage) ...[
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    int hour = timestamp.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }
}