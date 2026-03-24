import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final String lastMessage;
  final String lastMessageSenderId;
  final Timestamp? lastMessageTime;
  final Map<String, int> unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(
          data['participantNames'] ?? {}),
      participantPhotos: Map<String, String>.from(
          data['participantPhotos'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageTime: data['lastMessageTime'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  // Get the other participant's uid
  String getOtherUid(String myUid) {
    return participants.firstWhere((uid) => uid != myUid,
        orElse: () => '');
  }

  // Get the other participant's name
  String getOtherName(String myUid) {
    final otherUid = getOtherUid(myUid);
    return participantNames[otherUid] ?? 'Unknown';
  }

  // Get the other participant's photo
  String getOtherPhoto(String myUid) {
    final otherUid = getOtherUid(myUid);
    return participantPhotos[otherUid] ?? '';
  }
}