enum StickerKind {
  staticImage,
  gif,
  lottie,
  unicode;

  static StickerKind fromExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'gif':
        return StickerKind.gif;
      case 'json':
      case 'lottie':
        return StickerKind.lottie;
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
