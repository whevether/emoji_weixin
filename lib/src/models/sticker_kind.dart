enum StickerKind {
  staticImage,
  gif,
  unicode;

  static StickerKind fromExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'gif':
        return StickerKind.gif;
      default:
        return StickerKind.staticImage;
    }
  }

  static StickerKind fromName(String name) {
    return StickerKind.values.firstWhere(
      (e) => e.name == name,
      orElse: () => StickerKind.staticImage,
    );
  }
}
