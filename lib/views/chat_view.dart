import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chat_app_flutter/controllers/chat_controller.dart';
import 'package:chat_app_flutter/config/app_theme.dart';
import 'package:chat_app_flutter/controllers/main_controller.dart';
import 'package:chat_app_flutter/widgets/message_bubble.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  late final String chatId;
  late final ChatController controller;
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Get chatId from arguments
    chatId = Get.arguments?['chatId'] ?? '';

    // Create controller with tag if it doesn't exist
    if (!Get.isRegistered<ChatController>(tag: chatId)) {
      Get.put<ChatController>(ChatController(), tag: chatId);
    }

    // Get the controller with tag
    controller = Get.find<ChatController>(tag: chatId);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            // Clean up controller with tag before navigating back
            Get.delete<ChatController>(tag: chatId);
            Get.back();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Obx(() {
          final otherUser = controller.otherUser;
          if (otherUser == null) return const Text('Chat');

          return Row(
            children: [
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
                    Text(
                      otherUser.isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: otherUser.isOnline
                            ? AppTheme.successColor
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
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
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMyMessage = controller.isMyMessage(message);
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
                    onLongPress: isMyMessage
                        ? () => _showMessageOptions(message)
                        : null,
                  );
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        controller.onChatResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        controller.onChatPaused();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              'Start the conversation',
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
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
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
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
            Obx(
                  () => Container(
                decoration: BoxDecoration(
                  color: controller.isTyping
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: controller.isSending
                      ? null
                      : () => controller.sendMessage(),
                  icon: Icon(
                    Icons.send_rounded,
                    color: controller.isTyping
                        ? Colors.white
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Edit Message'),
              onTap: () {
                Get.back();
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete Message'),
              onTap: () {
                Get.back();
                _showDeleteDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(dynamic message) {
    final editController = TextEditingController(text: message.content);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Enter new message'),
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}