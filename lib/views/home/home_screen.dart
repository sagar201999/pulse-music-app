import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../player/player_screen.dart';
import '../auth/get_started_screen.dart';
import '../../services/audio_service.dart';
import '../../models/playlist_model.dart';
import '../../models/playlist_group_model.dart';
import '../../models/album_model.dart';
import 'playlist_detail_screen.dart';
import '../../widgets/song_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  List<Song> _songs = [];
  List<Playlist> _publicPlaylists = [];
  List<Song> _trendingSongs = [];
  List<Playlist> _userPlaylists = [];
  List<PlaylistGroup> _playlistGroups = [];
  User? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getAllSongs(),
        _auth.getUser(),
        _api.getPublicPlaylists(),
        _api.getAutoPlaylist('most-played'),
        _api.getUserPlaylists(), // Will return [] if not logged in
        _api.getPlaylistGroups(), // Fetch playlist groups
      ]);
      setState(() { 
        _songs = results[0] as List<Song>; 
        _user = results[1] as User?;
        _publicPlaylists = results[2] as List<Playlist>;
        _trendingSongs = results[3] as List<Song>;
        _userPlaylists = results[4] as List<Playlist>;
        _playlistGroups = results[5] as List<PlaylistGroup>;
        _loading = false; 
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _handleLogout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (Spotify Style) ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + App Name
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.play_fill, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Pulse Music',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  // Profile Avatar
                  GestureDetector(
                    onTap: () {
                      _showProfileMenu(context);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange, // Default avatar color
                        shape: BoxShape.circle,
                        image: (_user?.profileImage != null)
                          ? DecorationImage(image: CachedNetworkImageProvider(_user!.profileImage!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: (_user?.profileImage == null)
                        ? Center(
                            child: Text(
                              (_user?.username.isNotEmpty == true) ? _user!.username[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? _buildShimmer()
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppColors.primary,
                          backgroundColor: AppColors.cardColor,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Private Playlists (If logged in)
                                if (_userPlaylists.isNotEmpty) ...[
                                  _buildSectionTitle('Your Library'),
                                  _buildPlaylistRow(_userPlaylists),
                                ],

                                // Admin Playlists
                                if (_publicPlaylists.isNotEmpty) ...[
                                  _buildSectionTitle('Featured Curations'),
                                  _buildPlaylistRow(_publicPlaylists),
                                ],

                                // Auto Playlist
                                if (_trendingSongs.isNotEmpty) ...[
                                  _buildSectionTitle('Trending Now'),
                                  _buildHorizontalSongRow(_trendingSongs),
                                ],

                                // Playlist Groups (below Trending Now)
                                if (_playlistGroups.isNotEmpty) ...[
                                  for (final group in _playlistGroups) ...[
                                    _buildSectionTitle(group.name),
                                    _buildGroupRow(group),
                                  ],
                                ],

                                // All Songs
                                const SizedBox(height: 12),
                                _buildSectionTitle('All Songs'),
                                if (_songs.isEmpty) _buildEmpty(),
                                 ..._songs.asMap().entries.map((entry) => SongListTile(
                                  song: entry.value,
                                  playlist: _songs,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlayerScreen(
                                          song: entry.value, playlist: _songs),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlaylistRow(List<Playlist> lists) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: lists.length,
        itemBuilder: (context, i) {
          final p = lists[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: p)));
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.thumbnailUrl.isEmpty
                        ? Container(
                            width: 120,
                            height: 120,
                            color: AppColors.cardColor,
                            child: const Icon(CupertinoIcons.folder_fill, color: AppColors.secondary, size: 38),
                          )
                        : CachedNetworkImage(
                            imageUrl: p.thumbnailUrl,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              width: 120,
                              height: 120,
                              color: AppColors.cardColor,
                              child: const Icon(CupertinoIcons.folder_fill, color: AppColors.secondary, size: 38),
                            ),
                            errorWidget: (_, _, _) => Container(
                              width: 120,
                              height: 120,
                              color: AppColors.cardColor,
                              child: const Icon(Icons.folder, color: AppColors.secondary, size: 40),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${p.trackCount} tracks',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupRow(PlaylistGroup group) {
    final items = <dynamic>[...group.playlists, ...group.albums];
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          'No playlists or albums in this group',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final String title;
          final String subtitle;
          final String thumbnailUrl;
          final VoidCallback onTap;

          if (item is Playlist) {
            title = item.name;
            subtitle = '${item.trackCount} tracks';
            thumbnailUrl = item.thumbnailUrl;
            onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: item)),
              );
            };
          } else if (item is Album) {
            title = item.title;
            subtitle = 'Album • ${item.artist}';
            thumbnailUrl = item.thumbnailUrl;
            onTap = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(album: item)),
              );
            };
          } else {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 120,
                        height: 120,
                        color: AppColors.cardColor,
                        child: const Icon(CupertinoIcons.music_note, color: AppColors.secondary),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 120,
                        height: 120,
                        color: AppColors.cardColor,
                        child: const Icon(CupertinoIcons.music_note, color: AppColors.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSongRow(List<Song> songs) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, i) {
          final s = songs[i];
          return GestureDetector(
            onTap: () {
              AudioPlayerService().loadAndPlay(s, playlist: songs);
              Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(song: s, playlist: songs)));
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: s.thumbnailUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    s.artist,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange,
                  backgroundImage: _user?.profileImage != null 
                    ? CachedNetworkImageProvider(_user!.profileImage!) 
                    : null,
                  child: _user?.profileImage == null 
                    ? Text(_user?.username[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 24, color: Colors.white))
                    : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.username ?? 'Guest User',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _user?.email ?? '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.dividerColor),
            const SizedBox(height: 12),
            
            // Logout Button
            ListTile(
              leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardColor,
      highlightColor: AppColors.shimmerHigh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 8,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                color: AppColors.textPrimary,
                margin: const EdgeInsets.only(right: 14),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: AppColors.textPrimary, margin: const EdgeInsets.only(bottom: 8)),
                    Container(height: 12, width: 120, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.wifi_slash, color: AppColors.secondary, size: 64),
          const SizedBox(height: 20),
          const Text(
            'You\'re offline',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please go online to play songs.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.secondary),
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.music_note, color: AppColors.textSecondary, size: 52),
          SizedBox(height: 16),
          Text('No songs yet',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Upload songs from the admin dashboard.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

