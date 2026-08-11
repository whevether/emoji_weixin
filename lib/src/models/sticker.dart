import 'sticker_kind.dart';

class Sticker {
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

  final String id;
  final String packId;
  final String name;
  final StickerKind kind;
  final String? localPath;
  final String? assetPath;
  final String? networkUrl;
  final String? unicode;
  final DateTime? createdAt;

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
