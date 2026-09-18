/// Origin of a sticker pack / sticker entry.
enum StickerSource {
  /// Shipped with the package (e.g. Douyin catalog).
  builtin,

  /// User favorites / custom pack.
  custom,

  /// Imported from an external pack (legacy).
  imported,

  /// Saved from Klipy search.
  klipy;

  /// Parses a stored enum [name]; maps legacy `giphy` to [klipy].
  static StickerSource fromName(String name) {
    if (name == 'giphy') return StickerSource.klipy;
    return StickerSource.values.firstWhere(
      (e) => e.name == name,
      orElse: () => StickerSource.custom,
    );
  }
}
