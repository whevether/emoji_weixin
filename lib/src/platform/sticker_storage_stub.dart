import 'dart:typed_data';

class StickerStorageImpl {
  static Future<void> init() async {}

  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) {
    throw UnsupportedError('StickerStorage is not supported on this platform');
  }

  static Future<Uint8List?> readBytes(String ref) async => null;

  static Future<void> deletePackDir(String packId) async {}

  static String rootHint() => '';
}
