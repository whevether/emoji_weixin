enum StickerSource {
  builtin,
  custom,
  imported,
  klipy;

  static StickerSource fromName(String name) {
    if (name == 'giphy') return StickerSource.klipy;
    return StickerSource.values.firstWhere(
      (e) => e.name == name,
      orElse: () => StickerSource.custom,
    );
  }
}
