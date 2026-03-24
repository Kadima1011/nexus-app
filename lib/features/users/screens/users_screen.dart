import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/users_controller.dart';
import '../../profile/models/user_model.dart';
import '../../chat/screens/chat_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsersController(),
      child: Consumer<UsersController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppTheme.darkBg,
            appBar: AppBar(
              backgroundColor: AppTheme.darkBg,
              elevation: 0,
              title: const Text(
                'New Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search people...',
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white38),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                          : null,
                    ),
                  ),
                ),

                // Users list
                Expanded(
                  child: StreamBuilder<List<UserModel>>(
                    stream: controller.usersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const LoadingWidget();
                      }

                      final users = (snapshot.data ?? [])
                          .where((u) =>
                      _searchQuery.isEmpty ||
                          u.name
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          u.email
                              .toLowerCase()
                              .contains(_searchQuery))
                          .toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 60,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No users yet'
                                    : 'No results for "$_searchQuery"',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _UserTile(
                            user: user,
                            controller: controller,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final UserModel user;
  final UsersController controller;

  const _UserTile({
    required this.user,
    required this.controller,
  });

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _isLoading = false;

  Future<void> _startChat() async {
    setState(() => _isLoading = true);
    try {
      final conversationId = await widget.controller
          .getOrCreateConversation(widget.user.uid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              otherUser: widget.user,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            backgroundImage: widget.user.photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(widget.user.photoUrl)
                : null,
            child: widget.user.photoUrl.isEmpty
                ? Text(
              widget.user.name.isNotEmpty
                  ? widget.user.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
                : null,
          ),
          // Online indicator
          if (widget.user.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppTheme.onlineColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.darkBg, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        widget.user.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        widget.user.isOnline ? 'Online' : widget.user.email,
        style: TextStyle(
          color: widget.user.isOnline
              ? AppTheme.onlineColor
              : Colors.white.withOpacity(0.4),
          fontSize: 13,
        ),
      ),
      trailing: _isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
          strokeWidth: 2,
        ),
      )
          : Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: const Text(
          'Message',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: _startChat,
    );
  }
}