import 'builtin_emojis.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';

class BuiltinEmojiCatalog {
  static const packId = 'system_emoji';

  static StickerPack pack() {
    final stickers = [
      for (var i = 0; i < kBuiltinUnicodeEmojis.length; i++)
        Sticker(
          id: 'emoji_$i',
          packId: packId,
          name: kBuiltinUnicodeEmojis[i],
          kind: StickerKind.unicode,
          unicode: kBuiltinUnicodeEmojis[i],
        ),
    ];
    return StickerPack(
      id: packId,
      name: '表情',
      source: StickerSource.builtin,
      stickers: stickers,
    );
  }
}
