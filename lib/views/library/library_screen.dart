import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../models/playlist_model.dart';
import 'liked_songs_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await ApiService().getUserPlaylists();
      setState(() {
        _playlists = playlists;
      });
    } catch (e) {
      // Handle error gently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context); // close dialog immediately
                  final success = await ApiService().createUserPlaylist(name, '');
                  if (success) {
                    _fetchPlaylists(); // refresh
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create playlist')),
                      );
                    }
                  }
                }
              },
              child: const Text('CREATE', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, size: 26),
            onPressed: _showCreatePlaylistDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? const Center(
                  child: Text(
                    'No playlists yet. Create one!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _playlists.length + 1, // +1 for Liked Songs
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Static Liked Songs Item
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF450AF5), Color(0xFFC4E8C2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 28),
                          ),
                        ),
                        title: const Text(
                          'Liked Songs',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Playlist • You',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                          );
                        },
                      );
                    }

                    final playlist = _playlists[index - 1];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: CachedNetworkImage(
                            imageUrl: playlist.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Icon(CupertinoIcons.music_note, color: Colors.white54, size: 28),
                            errorWidget: (context, url, error) => const Icon(CupertinoIcons.music_note, color: Colors.white54, size: 28),
                          ),
                        ),
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text(
                        'Playlist • You',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      onTap: () {
                        // TODO: Navigate to playlist details to add/remove songs and play
                      },
                    );
                  },
                ),
    );
  }
}
