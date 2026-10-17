import 'dart:typed_data';

import 'storage_names.dart';

import 'sticker_storage_stub.dart'
    if (dart.library.io) 'sticker_storage_io.dart'
    if (dart.library.html) 'sticker_storage_web.dart'
    if (dart.library.js_interop) 'sticker_storage_web.dart'
    as impl;

/// Cross-platform sticker byte storage.
///
/// - IO (mobile/desktop): writes files under app documents
/// - Web / WASM: stores bytes in ToStore, returns `hive:<key>` refs
abstract final class StickerStorage {
  /// Initializes platform storage (documents dir or ToStore).
  static Future<void> init() => impl.StickerStorageImpl.init();

  /// Persist [bytes] and return a platform-specific reference path.
  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) async {
    validateStorageName(packId, label: 'packId');
    validateStorageName(filename, label: 'filename');
    await init();
    return impl.StickerStorageImpl.saveBytes(
      packId: packId,
      filename: filename,
      bytes: bytes,
    );
  }

  /// Reads bytes for a filesystem path or `hive:` [ref].
  static Future<Uint8List?> readBytes(String ref) async {
    await init();
    return impl.StickerStorageImpl.readBytes(ref);
  }

  /// Deletes one managed media reference; paths outside storage are rejected.
  static Future<void> deleteBytes(String ref) async {
    await init();
    await impl.StickerStorageImpl.deleteBytes(ref);
  }

  /// Whether [ref] points at a ToStore blob (`hive:` prefix).
  static bool isBlobRef(String? ref) => ref != null && ref.startsWith('hive:');

  /// Deletes stored media for [packId].
  static Future<void> deletePackDir(String packId) async {
    validateStorageName(packId, label: 'packId');
    await init();
    await impl.StickerStorageImpl.deletePackDir(packId);
  }

  /// Debug / legacy hint for the storage root (`hive` on web).
  static String rootHint() => impl.StickerStorageImpl.rootHint();
}
