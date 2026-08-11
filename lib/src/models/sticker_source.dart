enum StickerSource {
  builtin,
  custom,
  imported,
  giphy;

  static StickerSource fromName(String name) {
    return StickerSource.values.firstWhere(
      (e) => e.name == name,
      orElse: () => StickerSource.custom,
    );
  }
}
