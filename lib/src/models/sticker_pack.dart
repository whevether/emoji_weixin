import 'sticker.dart';
import 'sticker_source.dart';

/// A named collection of [Sticker]s (built-in, custom, or imported).
class StickerPack {
  /// Creates a sticker pack.
  const StickerPack({
    required this.id,
    required this.name,
    required this.source,
    this.coverPath,
    this.coverAsset,
    this.stickers = const [],
  });

  /// Unique pack id (e.g. `custom`, Douyin catalog id).
  final String id;

  /// Display name shown in the panel and manager.
  final String name;

  /// Where this pack came from.
  final StickerSource source;

  /// Local cover image path / blob ref, if any.
  final String? coverPath;

  /// Asset path for a built-in cover image, if any.
  final String? coverAsset;

  /// Stickers contained in this pack.
  final List<Sticker> stickers;

  /// Returns a copy with the given fields replaced.
  StickerPack copyWith({
    String? id,
    String? name,
    StickerSource? source,
    String? coverPath,
    String? coverAsset,
    List<Sticker>? stickers,
  }) {
    return StickerPack(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      coverPath: coverPath ?? this.coverPath,
      coverAsset: coverAsset ?? this.coverAsset,
      stickers: stickers ?? this.stickers,
    );
  }

  /// Serializes this pack to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'source': source.name,
        'coverPath': coverPath,
        'coverAsset': coverAsset,
        'stickers': stickers.map((e) => e.toJson()).toList(),
      };

  /// Deserializes a pack from [json].
  factory StickerPack.fromJson(Map<String, dynamic> json) {
    final rawStickers = json['stickers'] as List<dynamic>? ?? const [];
    return StickerPack(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      source: StickerSource.fromName(json['source'] as String? ?? 'custom'),
      coverPath: json['coverPath'] as String?,
      coverAsset: json['coverAsset'] as String?,
      stickers: rawStickers
          .map((e) => Sticker.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
