import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:emoji_weixin/src/ui/sticker_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new strings are non-empty for every locale', () {
    for (final locale in EmojiWeixinLocale.values) {
      final s = EmojiWeixinStrings.of(locale);
      for (final text in [
        s.searchFailedMessage,
        s.loadFailedMessage,
        s.retry,
        s.favoritesPack,
        s.addToFavorites,
        s.addedToFavorites,
        s.send,
        s.pinToTop,
        s.deleteKey,
        s.emojiSearchHint,
      ]) {
        expect(text.trim(), isNotEmpty, reason: '$locale');
      }
    }
  });

  test('favorites cap is positive', () {
    expect(StickerRepository.maxCustomStickers, greaterThan(0));
  });

  test('unicode emoji cannot be added to favorites', () async {
    final added = await addStickerToFavorites(
      const Sticker(
        id: 'e',
        packId: 'emoji',
        name: '😀',
        kind: StickerKind.unicode,
        unicode: '😀',
      ),
    );
    expect(added, isFalse);
  });
}
