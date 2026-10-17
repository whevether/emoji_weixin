@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:emoji_weixin/src/data/emoji_store.dart';
import 'package:emoji_weixin/src/platform/sticker_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'web blob cleanup spans multiple pages and preserves a similar pack id',
    () async {
      final db = await EmojiStore.instance.open();
      final pack = 'test_${DateTime.now().microsecondsSinceEpoch}';
      final other = '${pack}_other';
      final result = await db.batchInsert(EmojiStore.blobTable, [
        for (var i = 0; i < 225; i++)
          {
            'key': '$pack/$i.gif',
            'bytes': Uint8List.fromList([1, 2, 3]),
          },
        {
          'key': '$other/keep.gif',
          'bytes': Uint8List.fromList([4, 5, 6]),
        },
      ]);
      expect(result.hasErrors, isFalse);
      await StickerStorage.deletePackDir(pack);
      expect(await StickerStorage.readBytes('hive:$pack/0.gif'), isNull);
      expect(await StickerStorage.readBytes('hive:$pack/224.gif'), isNull);
      expect(
        await StickerStorage.readBytes('hive:$other/keep.gif'),
        orderedEquals([4, 5, 6]),
      );
      final remaining = await db
          .query(EmojiStore.blobTable)
          .where('key', '>=', '$pack/')
          .where('key', '<', '${pack}0')
          .limit(300);
      expect(remaining.data, isEmpty);
      await StickerStorage.deletePackDir(other);
      await db.close();
    },
  );
}
