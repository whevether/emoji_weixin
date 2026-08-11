import 'dart:typed_data';

import 'sticker_storage_stub.dart'
    if (dart.library.io) 'sticker_storage_io.dart'
    if (dart.library.html) 'sticker_storage_web.dart' as impl;

/// Cross-platform sticker byte storage.
///
/// - IO (mobile/desktop): writes files under app documents
/// - Web: stores bytes in a Hive box, returns `hive:<key>` refs
abstract final class StickerStorage {
  static Future<void> init() => impl.StickerStorageImpl.init();

  /// Persist [bytes] and return a platform-specific reference path.
  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) =>
      impl.StickerStorageImpl.saveBytes(
        packId: packId,
        filename: filename,
        bytes: bytes,
      );

  static Future<Uint8List?> readBytes(String ref) =>
      impl.StickerStorageImpl.readBytes(ref);

  static bool isBlobRef(String? ref) =>
      ref != null && ref.startsWith('hive:');

  static Future<void> deletePackDir(String packId) =>
      impl.StickerStorageImpl.deletePackDir(packId);

  static String rootHint() => impl.StickerStorageImpl.rootHint();
}
