import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String slug;
  final String thumbnailUrl;
  final String color;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.thumbnailUrl = '',
    this.color = '#1DB954',
    this.order = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      slug: json['slug'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      color: json['color'] ?? '#1DB954',
      order: (json['order'] ?? 0).toInt(),
    );
  }

  /// Converts "#1DB954" → Flutter Color
  Color get parsedColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1DB954);
    }
  }
}
