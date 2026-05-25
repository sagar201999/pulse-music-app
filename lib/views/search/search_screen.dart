import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';
import '../player/player_screen.dart';
import '../../widgets/song_list_tile.dart';

// ── Search Screen ──────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Category> _categories = [];
  List<Song> _results = [];
  bool _loadingCategories = true;
  bool _searching = false;
  bool _hasSearched = false;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _controller.addListener(_onQueryChanged);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.getCategories();
      if (mounted) setState(() { _categories = cats; _loadingCategories = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _onQueryChanged() {
    final text = _controller.text.trim();
    if (text == _query) return;
    _query = text;
    _debounce?.cancel();

    if (text.isEmpty) {
      setState(() { _results = []; _hasSearched = false; _searching = false; });
      return;
    }

    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _doSearch(text));
  }

  Future<void> _doSearch(String q) async {
    try {
      final songs = await _api.searchSongs(q);
      if (mounted && _query == q) {
        setState(() { _results = songs; _searching = false; _hasSearched = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _searching = false; _hasSearched = true; });
    }
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() { _query = ''; _results = []; _hasSearched = false; _searching = false; });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showResults = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: const Text(
                'Search',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // ── Search Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.primary.withOpacity(0.7)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(CupertinoIcons.search, color: AppColors.textSecondary, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        cursorColor: AppColors.primary,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Songs, artists, keywords…',
                          hintStyle: TextStyle(color: AppColors.textDisabled, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: showResults ? _buildResultsView() : _buildBrowseView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results View ────────────────────────────────────────────────────────────
  Widget _buildResultsView() {
    if (_searching) {
      return _buildSearchShimmer();
    }
    if (_hasSearched && _results.isEmpty) {
      return _buildNoResults();
    }
    if (_results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            '${_results.length} result${_results.length == 1 ? '' : 's'} for "$_query"',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: _results.length,
            itemBuilder: (ctx, i) => SongListTile(
              song: _results[i],
              playlist: _results,
              onTap: () {
                AudioPlayerService().loadAndPlay(_results[i], playlist: _results);
                Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => PlayerScreen(song: _results[i], playlist: _results)));
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Browse / Categories View ─────────────────────────────────────────────────
  Widget _buildBrowseView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Text(
              'Browse Categories',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _loadingCategories
              ? _buildCategoryShimmer()
              : _categories.isEmpty
                  ? _buildNoCats()
                  : _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemBuilder: (ctx, i) => _CategoryCard(
          category: _categories[i],
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => CategorySongsScreen(category: _categories[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardColor,
      highlightColor: AppColors.shimmerHigh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(width: 56, height: 56, color: AppColors.textPrimary,
                  margin: const EdgeInsets.only(right: 14)),
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

  Widget _buildCategoryShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardColor,
      highlightColor: AppColors.shimmerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.search, color: AppColors.secondary, size: 64),
          const SizedBox(height: 16),
          const Text('No results found',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check the spelling.',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoCats() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text('No categories yet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ),
    );
  }
}

// ── Category Card (Spotify-style) ────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: category.parsedColor,
          child: Stack(
            children: [
              // Category Name — left side
              Positioned(
                top: 0, bottom: 0, left: 0,
                right: 80,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // Category Image — bottom-right corner, tilted
              Positioned(
                right: -8,
                bottom: -6,
                child: Transform.rotate(
                  angle: 0.35, // ~20 degrees
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: category.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: category.thumbnailUrl,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _fallbackIcon(),
                          )
                        : _fallbackIcon(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: 68,
      height: 68,
      color: Colors.black26,
      child: const Icon(CupertinoIcons.music_note, color: Colors.white54, size: 30),
    );
  }
}

// ── Search Song Tile ──────────────────────────────────────────────────────────
class _SearchSongTile extends StatelessWidget {
  final Song song;
  final List<Song> playlist;

  const _SearchSongTile({required this.song, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AudioPlayerService().loadAndPlay(song, playlist: playlist);
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(song: song, playlist: playlist)));
      },
      splashColor: AppColors.textPrimary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 56, height: 56,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 56, height: 56, color: AppColors.cardColor,
                  child: const Icon(Icons.music_note, color: AppColors.secondary, size: 22),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 56, height: 56, color: AppColors.cardColor,
                  child: const Icon(Icons.music_note, color: AppColors.secondary, size: 22),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Title + Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          song.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (song.isExplicit)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text('E',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Play icon
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.play_circle, color: AppColors.textSecondary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Songs Screen ─────────────────────────────────────────────────────
class CategorySongsScreen extends StatefulWidget {
  final Category category;

  const CategorySongsScreen({super.key, required this.category});

  @override
  State<CategorySongsScreen> createState() => _CategorySongsScreenState();
}

class _CategorySongsScreenState extends State<CategorySongsScreen> {
  final ApiService _api = ApiService();
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() { _loading = true; _error = null; });
    try {
      final songs = await _api.getSongsByCategory(widget.category.name);
      if (mounted) setState(() { _songs = songs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = widget.category.parsedColor;
    final darkCatColor = Color.lerp(catColor, Colors.black, 0.6)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Colored SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: darkCatColor,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.chevron_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [catColor, darkCatColor],
                      ),
                    ),
                  ),
                  // Category image (right side)
                  if (widget.category.thumbnailUrl.isNotEmpty)
                    Positioned(
                      right: -20,
                      bottom: 20,
                      child: Opacity(
                        opacity: 0.5,
                        child: Transform.rotate(
                          angle: 0.25,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: widget.category.thumbnailUrl,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Gradient overlay bottom
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.background],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Songs ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _loading
                ? _buildShimmer()
                : _error != null
                    ? _buildError()
                    : _songs.isEmpty
                        ? _buildEmpty()
                        : const SizedBox.shrink(),
          ),

          if (!_loading && _error == null && _songs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => SongListTile(
                song: _songs[i],
                playlist: _songs,
                onTap: () {
                  AudioPlayerService().loadAndPlay(_songs[i], playlist: _songs);
                  Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => PlayerScreen(song: _songs[i], playlist: _songs)));
                },
              ),
                childCount: _songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardColor,
      highlightColor: AppColors.shimmerHigh,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 6,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(width: 56, height: 56, color: AppColors.textPrimary,
                  margin: const EdgeInsets.only(right: 14)),
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(CupertinoIcons.wifi_exclamationmark, color: AppColors.secondary, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadSongs,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary),
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(CupertinoIcons.music_note, color: AppColors.secondary, size: 52),
            SizedBox(height: 16),
            Text('No songs in this category',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
