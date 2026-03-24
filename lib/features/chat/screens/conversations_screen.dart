import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/conversation_model.dart';
import '../../profile/models/user_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../users/screens/users_screen.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileController()),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: IndexedStack(
              index: _currentIndex,
              children: const [
                _ChatsBody(),
                ProfileScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) =>
                  setState(() => _currentIndex = index),
              backgroundColor: AppTheme.darkSurface,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.white30,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatsBody extends StatelessWidget {
  const _ChatsBody();

  Stream<List<ConversationModel>> _conversationsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ConversationModel.fromDoc(d))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nexus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const UsersScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _conversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the edit icon to start a chat',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withOpacity(0.05),
              height: 1,
              indent: 80,
            ),
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final otherName = convo.getOtherName(myUid);
              final otherPhoto = convo.getOtherPhoto(myUid);
              final otherUid = convo.getOtherUid(myUid);
              final unread = convo.unreadCount[myUid] ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor:
                  AppTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: otherPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(otherPhoto)
                      : null,
                  child: otherPhoto.isEmpty
                      ? Text(
                    otherName.isNotEmpty
                        ? otherName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                title: Text(
                  otherName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: unread > 0
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  convo.lastMessage.isEmpty
                      ? 'Tap to start chatting'
                      : convo.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread > 0
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: unread > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (convo.lastMessageTime != null)
                      Text(
                        timeago.format(
                            convo.lastMessageTime!.toDate()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                        ),
                      ),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: convo.id,
                      otherUser: UserModel(
                        uid: otherUid,
                        name: otherName,
                        email: '',
                        photoUrl: otherPhoto,
                        bio: '',
                        isOnline: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UsersScreen()),
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
    );
  }
}