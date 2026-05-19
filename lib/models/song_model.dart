import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String thumbnailUrl;
  final String? videoThumbnail;
  final String? category;
  final List<String> keywords;
  final int duration;
  final String? cloudinaryId;
  final String hexColor;
  final bool isExplicit;
  final int playCount;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.thumbnailUrl,
    this.videoThumbnail,
    this.category,
    this.keywords = const [],
    required this.duration,
    this.cloudinaryId,
    this.hexColor = '#121212',
    this.isExplicit = false,
    this.playCount = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      audioUrl: json['audioUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoThumbnail: json['videoThumbnail'],
      category: json['category'],
      keywords: List<String>.from(json['keywords'] ?? []),
      duration: (json['duration'] ?? 0).toInt(),
      cloudinaryId: json['cloudinaryId'],
      hexColor: json['hexColor'] ?? '#121212',
      isExplicit: json['isExplicit'] ?? false,
      playCount: (json['playCount'] ?? 0).toInt(),
    );
  }

  /// Converts "#1a1a2e" → Flutter Color
  Color get parsedHexColor {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF121212);
    }
  }

  /// mm:ss formatted duration
  String get formattedDuration {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
