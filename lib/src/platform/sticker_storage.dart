import 'dart:typed_data';

import 'sticker_storage_stub.dart'
    if (dart.library.io) 'sticker_storage_io.dart'
    if (dart.library.html) 'sticker_storage_web.dart'
    if (dart.library.js_interop) 'sticker_storage_web.dart' as impl;

/// Cross-platform sticker byte storage.
///
/// - IO (mobile/desktop): writes files under app documents
/// - Web / WASM: stores bytes in a Hive box, returns `hive:<key>` refs
abstract final class StickerStorage {
  /// Initializes platform storage (documents dir or Hive box).
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

  /// Reads bytes for a filesystem path or `hive:` [ref].
  static Future<Uint8List?> readBytes(String ref) =>
      impl.StickerStorageImpl.readBytes(ref);

  /// Whether [ref] points at a Hive blob (`hive:` prefix).
  static bool isBlobRef(String? ref) =>
      ref != null && ref.startsWith('hive:');

  /// Deletes stored media for [packId].
  static Future<void> deletePackDir(String packId) =>
      impl.StickerStorageImpl.deletePackDir(packId);

  /// Debug / legacy hint for the storage root (`hive` on web).
  static String rootHint() => impl.StickerStorageImpl.rootHint();
}
