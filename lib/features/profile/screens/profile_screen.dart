import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/profile_controller.dart';
import '../widgets/edit_profile_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
      Provider.of<ProfileController>(context, listen: false);
      final uid = controller.currentUser?.uid;
      if (uid != null) controller.fetchProfile(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, profile, _) {
        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            backgroundColor: AppTheme.darkBg,
            elevation: 0,
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (profile.userProfile != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white70),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: profile,
                        child: EditProfileSheet(
                          controller: profile,
                          user: profile.userProfile!,
                        ),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: Icon(Icons.logout,
                    color: Colors.white.withOpacity(0.5), size: 22),
                onPressed: () async {
                  final auth = AuthController();
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
          body: profile.isLoading
              ? const LoadingWidget()
              : profile.userProfile == null
              ? Center(
            child: Text(
              'Profile not found.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4)),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar
                CircleAvatar(
                  radius: 56,
                  backgroundColor:
                  AppTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: profile
                      .userProfile!.photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(
                      profile.userProfile!.photoUrl)
                      : null,
                  child: profile
                      .userProfile!.photoUrl.isEmpty
                      ? Text(
                    profile.userProfile!.name.isNotEmpty
                        ? profile.userProfile!.name[0]
                        .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  profile.userProfile!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  profile.userProfile!.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),

                // Online status
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.onlineColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: AppTheme.onlineColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Bio
                if (profile.userProfile!.bio.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Text(
                      profile.userProfile!.bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                        Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Divider(
                    color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 24),

                // Stats row
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('Member since', '2025'),
                    _divider(),
                    _statItem('Status', 'Active'),
                    _divider(),
                    _statItem('App', 'Nexus'),
                  ],
                ),

                const SizedBox(height: 40),

                // Edit profile button
                OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          ChangeNotifierProvider.value(
                            value: profile,
                            child: EditProfileSheet(
                              controller: profile,
                              user: profile.userProfile!,
                            ),
                          ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined,
                      size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    minimumSize:
                    const Size(double.infinity, 50),
                    side: BorderSide(
                        color: AppTheme.primaryColor
                            .withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }
}