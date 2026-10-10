import 'package:tostore/tostore.dart';

import 'emoji_store_path_stub.dart'
    if (dart.library.io) 'emoji_store_path_io.dart';

/// Process-wide ToStore database for sticker packs and Web blob bytes.
class EmojiStore {
  EmojiStore._();

  /// Shared instance opened by sticker persistence and Web sticker storage.
  static final EmojiStore instance = EmojiStore._();

  /// Database directory name under [dbPath].
  static const dbName = 'emoji_weixin';

  /// Table that stores Web / WASM sticker bytes.
  static const blobTable = 'sticker_blobs';

  /// Schema passed to [ToStore.open]. The blob table is unused on IO.
  static const schemas = <TableSchema>[
    TableSchema(
      name: blobTable,
      primaryKeyConfig: PrimaryKeyConfig(
        name: 'key',
        type: PrimaryKeyType.none,
      ),
      fields: [
        FieldSchema(
          name: 'bytes',
          type: DataType.blob,
          nullable: false,
        ),
      ],
    ),
  ];

  ToStore? _db;

  /// Opens the database once. Later calls return the same instance.
  Future<ToStore> open() async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await ToStore.open(
      dbPath: await emojiStorePath(),
      dbName: dbName,
      schemas: schemas,
    );
    _db = opened;
    return opened;
  }

  /// The open database. Throws if [open] has not finished.
  ToStore get db {
    final opened = _db;
    if (opened == null) {
      throw StateError('EmojiStore not initialized');
    }
    return opened;
  }
}
