import 'sticker_kind.dart';

/// A single sticker (image, GIF, or unicode emoji).
class Sticker {
  /// Creates a sticker with the given identity and media references.
  const Sticker({
    required this.id,
    required this.packId,
    required this.name,
    required this.kind,
    this.localPath,
    this.assetPath,
    this.networkUrl,
    this.unicode,
    this.createdAt,
  });

  /// Unique sticker id within the app.
  final String id;

  /// Id of the [StickerPack] this sticker belongs to.
  final String packId;

  /// Display name shown in the UI.
  final String name;

  /// How this sticker is encoded / rendered.
  final StickerKind kind;

  /// Local filesystem path or `hive:` blob ref for custom stickers.
  final String? localPath;

  /// Flutter asset path for built-in pack stickers.
  final String? assetPath;

  /// Remote URL (e.g. Klipy original), if any.
  final String? networkUrl;

  /// Unicode code point string when [kind] is [StickerKind.unicode].
  final String? unicode;

  /// When the sticker was added; may be null for built-ins.
  final DateTime? createdAt;

  /// Returns a copy with the given fields replaced.
  Sticker copyWith({
    String? id,
    String? packId,
    String? name,
    StickerKind? kind,
    String? localPath,
    String? assetPath,
    String? networkUrl,
    String? unicode,
    DateTime? createdAt,
  }) {
    return Sticker(
      id: id ?? this.id,
      packId: packId ?? this.packId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      localPath: localPath ?? this.localPath,
      assetPath: assetPath ?? this.assetPath,
      networkUrl: networkUrl ?? this.networkUrl,
      unicode: unicode ?? this.unicode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes this sticker to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'packId': packId,
        'name': name,
        'kind': kind.name,
        'localPath': localPath,
        'assetPath': assetPath,
        'networkUrl': networkUrl,
        'unicode': unicode,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// Deserializes a sticker from [json].
  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'] as String,
      packId: json['packId'] as String,
      name: json['name'] as String? ?? '',
      kind: StickerKind.fromName(json['kind'] as String? ?? 'staticImage'),
      localPath: json['localPath'] as String?,
      assetPath: json['assetPath'] as String?,
      networkUrl: json['networkUrl'] as String?,
      unicode: json['unicode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
