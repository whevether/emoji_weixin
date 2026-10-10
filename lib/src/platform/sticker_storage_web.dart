import 'dart:typed_data';

import 'package:tostore/tostore.dart';

import '../data/emoji_store.dart';

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
    final key = '$packId/$filename';
    await _db.upsert(EmojiStore.blobTable, {
      'key': key,
      'bytes': bytes,
    });
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

  /// Deletes blob rows whose key starts with [packId]/.
  static Future<void> deletePackDir(String packId) async {
    final prefix = '$packId/';
    var page = await _db
        .query(EmojiStore.blobTable)
        .where('key', 'LIKE', '$prefix%')
        .limit(200);
    while (true) {
      final keys = <String>[];
      for (final row in page.data) {
        final key = row['key'];
        if (key is String && key.startsWith(prefix)) keys.add(key);
      }
      for (final key in keys) {
        await _db.delete(EmojiStore.blobTable).where('key', '=', key);
      }
      if (!page.hasMore) break;
      final next = await page.next();
      if (next.data.isEmpty) break;
      page = next;
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
