import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final String? imageUrl;
  final MessageType type;
  final Timestamp createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      type: data['type'] == 'image'
          ? MessageType.image
          : MessageType.text,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}

enum MessageType { text, image }