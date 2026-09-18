/// How a sticker is encoded / rendered.
enum StickerKind {
  /// Static PNG/JPG/WebP (or similar).
  staticImage,

  /// Animated GIF.
  gif,

  /// Unicode emoji character(s).
  unicode;

  /// Infers kind from a file extension (e.g. `gif` → [gif]).
  static StickerKind fromExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'gif':
        return StickerKind.gif;
      default:
        return StickerKind.staticImage;
    }
  }

  /// Parses a stored enum [name], defaulting to [staticImage].
  static StickerKind fromName(String name) {
    return StickerKind.values.firstWhere(
      (e) => e.name == name,
      orElse: () => StickerKind.staticImage,
    );
  }
}
