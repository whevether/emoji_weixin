import 'dart:typed_data';

/// Stub sticker storage for platforms without IO or web storage.
class StickerStorageImpl {
  /// No-op initialization.
  static Future<void> init() async {}

  /// Always throws; storage is unsupported on this platform.
  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) {
    throw UnsupportedError('StickerStorage is not supported on this platform');
  }

  /// Always returns `null` on stub platforms.
  static Future<Uint8List?> readBytes(String ref) async => null;

  /// No-op delete.
  static Future<void> deletePackDir(String packId) async {}

  /// Empty root hint.
  static String rootHint() => '';
}
