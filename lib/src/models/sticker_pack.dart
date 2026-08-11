import 'sticker.dart';
import 'sticker_source.dart';

class StickerPack {
  const StickerPack({
    required this.id,
    required this.name,
    required this.source,
    this.coverPath,
    this.coverAsset,
    this.stickers = const [],
  });

  final String id;
  final String name;
  final StickerSource source;
  final String? coverPath;
  final String? coverAsset;
  final List<Sticker> stickers;

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'source': source.name,
        'coverPath': coverPath,
        'coverAsset': coverAsset,
        'stickers': stickers.map((e) => e.toJson()).toList(),
      };

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
