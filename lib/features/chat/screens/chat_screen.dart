import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import '../../profile/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
      Provider.of<ChatController>(context, listen: false);
      controller.markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(ChatController controller) async {
    final content = _messageController.text;
    if (content.trim().isEmpty) return;
    _messageController.clear();
    await controller.sendMessage(
      conversationId: widget.conversationId,
      content: content,
      otherUid: widget.otherUser.uid,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: Consumer<ChatController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppTheme.darkBg,
            appBar: _buildAppBar(controller),
            body: Column(
              children: [
                // Messages list
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: controller
                        .messagesStream(widget.conversationId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const LoadingWidget();
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme
                                    .primaryColor
                                    .withOpacity(0.1),
                                backgroundImage: widget
                                    .otherUser.photoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                    widget.otherUser.photoUrl)
                                    : null,
                                child: widget
                                    .otherUser.photoUrl.isEmpty
                                    ? Text(
                                  widget.otherUser.name
                                      .isNotEmpty
                                      ? widget.otherUser.name[0]
                                      .toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.otherUser.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Say hi to start the conversation!',
                                style: TextStyle(
                                  color:
                                  Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Mark as read when messages load
                      controller.markAsRead(widget.conversationId);
                      _scrollToBottom();

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMine = message.senderId ==
                              controller.currentUid;

                          // Show time if last message or
                          // next message is from different sender
                          final showTime = index ==
                              messages.length - 1 ||
                              messages[index + 1].senderId !=
                                  message.senderId;

                          return MessageBubble(
                            message: message,
                            isMine: isMine,
                            showTime: showTime,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Input bar
                _buildInputBar(context, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatController controller) {
    return AppBar(
      backgroundColor: AppTheme.darkSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(
                widget.otherUser.photoUrl)
                : null,
            child: widget.otherUser.photoUrl.isEmpty
                ? Text(
              widget.otherUser.name.isNotEmpty
                  ? widget.otherUser.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Online status stream
                StreamBuilder<bool>(
                  stream:
                  controller.onlineStream(widget.otherUser.uid),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data ?? false;
                    return Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? AppTheme.onlineColor
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
      BuildContext context, ChatController controller) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          // Image button
          IconButton(
            icon: const Icon(Icons.image_outlined,
                color: AppTheme.primaryColor),
            onPressed: controller.isSending
                ? null
                : () => controller.sendImage(
              conversationId: widget.conversationId,
              otherUid: widget.otherUser.uid,
            ),
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(controller),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: AppTheme.darkCard,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          controller.isSending
              ? const SizedBox(
            width: 44,
            height: 44,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            ),
          )
              : GestureDetector(
            onTap: () => _sendMessage(controller),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
