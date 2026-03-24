import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.showTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 64 : 16,
        right: isMine ? 16 : 64,
        top: 2,
        bottom: showTime ? 12 : 2,
      ),
      child: Column(
        crossAxisAlignment:
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            decoration: BoxDecoration(
              color: isMine
                  ? AppTheme.sentBubble
                  : AppTheme.receivedBubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
            ),
            child: message.type == MessageType.image &&
                message.imageUrl != null
                ? _buildImageBubble()
                : _buildTextBubble(),
          ),

          // Time + read receipt
          if (showTime) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a')
                      .format(message.createdAt.toDate()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? AppTheme.primaryColor
                        : Colors.white38,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMine ? Colors.white : Colors.white.withOpacity(0.9),
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImageBubble() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMine ? 18 : 4),
        bottomRight: Radius.circular(isMine ? 4 : 18),
      ),
      child: CachedNetworkImage(
        imageUrl: message.imageUrl!,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 220,
          height: 220,
          color: AppTheme.darkSurface,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 220,
          height: 100,
          color: AppTheme.darkSurface,
          child: const Icon(Icons.broken_image_outlined,
              color: Colors.white38),
        ),
      ),
    );
  }
}