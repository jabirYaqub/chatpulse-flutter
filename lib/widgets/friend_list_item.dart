import 'package:flutter/material.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/config/app_theme.dart';

class FriendListItem extends StatelessWidget {
  final UserModel friend;
  final String lastSeenText;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onBlock;

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
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
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
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      ),
                    )
                        : _buildDefaultAvatar(),
                  ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friend.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastSeenText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: friend.isOnline ? AppTheme.successColor : AppTheme.textSecondaryColor,
                        fontWeight: friend.isOnline ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'message':
                      onTap();
                      break;
                    case 'remove':
                      onRemove();
                      break;
                    case 'block':
                      onBlock();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'message',
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                      title: Text('Message'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove, color: AppTheme.errorColor),
                      title: Text('Remove Friend'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      leading: Icon(Icons.block, color: AppTheme.errorColor),
                      title: Text('Block'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
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