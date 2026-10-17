import 'dart:typed_data';

import 'package:tostore/tostore.dart';

import '../data/emoji_store.dart';
import '../data/database_result.dart';
import 'storage_names.dart';

/// Web / WASM sticker storage backed by a ToStore blob table.
class StickerStorageImpl {
  /// Opens the shared ToStore database.
  static Future<void> init() async {
    await EmojiStore.instance.open();
  }

  static ToStore get _db => EmojiStore.instance.db;

  /// Stores [bytes] and returns a `hive:<packId>/<filename>` ref.
  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) async {
    validateStorageName(packId, label: 'packId');
    validateStorageName(filename, label: 'filename');
    final key = '$packId/$filename';
    final result = await _db.upsert(EmojiStore.blobTable, {
      'key': key,
      'bytes': bytes,
    });
    requireDatabaseSuccess(result, 'Save sticker media');
    return 'hive:$key';
  }

  /// Reads bytes for a `hive:` [ref].
  static Future<Uint8List?> readBytes(String ref) async {
    if (!ref.startsWith('hive:')) return null;
    final key = ref.substring('hive:'.length);
    final row = await _db
        .query(EmojiStore.blobTable)
        .whereEqual('key', key)
        .first();
    return _asBytes(row?['bytes']);
  }

  /// Deletes one blob with a validated storage reference.
  static Future<void> deleteBytes(String ref) async {
    if (!ref.startsWith('hive:')) throw ArgumentError('Expected a blob ref');
    final parts = ref.substring(5).split('/');
    if (parts.length != 2) throw ArgumentError('Invalid blob ref');
    for (final part in parts) {
      validateStorageName(part);
    }
    requireDatabaseSuccess(
      await _db.delete(EmojiStore.blobTable).whereEqual('key', parts.join('/')),
      'Delete sticker media',
    );
  }

  /// Deletes blobs in bounded batches, without offset pagination while deleting.
  static Future<void> deletePackDir(String packId) async {
    validateStorageName(packId, label: 'packId');
    final prefix = '$packId/';
    while (true) {
      final page = await _db
          .query(EmojiStore.blobTable)
          .where('key', '>=', prefix)
          .where('key', '<', '${packId}0')
          .limit(200);
      if (page.hasErrors) throw StateError('Read sticker media failed');
      final keys = page.data
          .map((row) => row['key'])
          .whereType<String>()
          .where((key) => key.startsWith(prefix))
          .toList();
      if (keys.isEmpty) break;
      for (final key in keys) {
        await deleteBytes('hive:$key');
      }
    }
  }

  /// Constant root hint used on web.
  static String rootHint() => 'hive';
}

Uint8List? _asBytes(dynamic value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  return null;
}
