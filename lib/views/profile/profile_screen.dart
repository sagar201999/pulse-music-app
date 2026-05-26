import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/get_started_screen.dart';
import 'edit_profile_screen.dart';
import '../library/liked_songs_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _loading = true);
    final user = await _auth.getUser();
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  void _handleLogout() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to log out of Pulse?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDisabled)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _auth.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const GetStartedScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final likedCount = _auth.likedSongIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // ── Profile Header Title ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.glassPill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(CupertinoIcons.pencil, color: Colors.white, size: 20),
                                  onPressed: () async {
                                    if (_user == null) return;
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
                                    );
                                    if (result == true) {
                                      _loadUserProfile();
                                    }
                                  },
                                  tooltip: 'Edit Profile',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.glassPill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 20),
                                  onPressed: _handleLogout,
                                  tooltip: 'Logout',
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Profile Avatar with glowing borders ────────────────
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Glow Ring
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: AppColors.accentGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                            // Inner Space Ring
                            Container(
                              width: 110,
                              height: 110,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Profile Image
                            Container(
                              width: 102,
                              height: 102,
                              decoration: BoxDecoration(
                                color: AppColors.cardColor,
                                shape: BoxShape.circle,
                                image: (_user?.profileImage != null)
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(_user!.profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (_user?.profileImage == null)
                                  ? Center(
                                      child: Text(
                                        (_user?.username.isNotEmpty == true)
                                            ? _user!.username[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── User Information (Name & Email) ───────────────────
                      Text(
                        _user?.username ?? 'Guest User',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _user?.email ?? 'No email linked',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Stats Row Cards (Glassmorphism look) ───────────────
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: _buildStatCard(
                                icon: CupertinoIcons.heart_fill,
                                iconColor: Colors.redAccent,
                                title: 'Liked Songs',
                                value: '$likedCount',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              icon: CupertinoIcons.person_crop_circle_fill,
                              iconColor: AppColors.primaryLight,
                              title: 'Gender',
                              value: _user?.gender ?? 'Not Specified',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Settings / Details Options List ───────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Account Settings',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildOptionTile(
                        icon: CupertinoIcons.mail_solid,
                        title: 'Email Address',
                        subtitle: _user?.email ?? 'Unknown',
                      ),
                      _buildOptionTile(
                        icon: CupertinoIcons.shield_fill,
                        title: 'Account Status',
                        subtitle: 'Premium Member',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.accentGradient),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _buildOptionTile(
                        icon: CupertinoIcons.slider_horizontal_3,
                        title: 'Audio Equalizer',
                        subtitle: 'Dolby Atmos Audio Enabled',
                        trailing: const Icon(CupertinoIcons.right_chevron, color: AppColors.textDisabled, size: 16),
                      ),
                      _buildOptionTile(
                        icon: CupertinoIcons.speaker_2_fill,
                        title: 'Streaming Quality',
                        subtitle: 'Very High (320kbps)',
                        trailing: const Icon(CupertinoIcons.right_chevron, color: AppColors.textDisabled, size: 16),
                      ),

                      const SizedBox(height: 24),

                      // ── Logout Action Button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 20),
                          label: const Text(
                            'Log Out from Pulse',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60), // Add padding for bottom navigation
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassCard.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.glassPill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
