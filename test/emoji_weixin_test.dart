import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sticker serialization roundtrip', () {
    final sticker = Sticker(
      id: '1',
      packId: 'custom',
      name: 'test',
      kind: StickerKind.gif,
      localPath: '/tmp/a.gif',
    );
    final restored = Sticker.fromJson(sticker.toJson());
    expect(restored.id, '1');
    expect(restored.kind, StickerKind.gif);
    expect(restored.localPath, '/tmp/a.gif');
  });

  test('StickerKind from extension', () {
    expect(StickerKind.fromExtension('gif'), StickerKind.gif);
    expect(StickerKind.fromExtension('json'), StickerKind.staticImage);
    expect(StickerKind.fromExtension('png'), StickerKind.staticImage);
  });

  test('EmojiWeixinLocale.fromCode', () {
    expect(EmojiWeixinLocale.fromCode('zh-CN'), EmojiWeixinLocale.zh);
    expect(EmojiWeixinLocale.fromCode('en_US'), EmojiWeixinLocale.en);
    expect(EmojiWeixinLocale.fromCode('vi'), EmojiWeixinLocale.vi);
    expect(EmojiWeixinLocale.fromCode('id'), EmojiWeixinLocale.id);
    expect(EmojiWeixinLocale.fromCode('fil'), EmojiWeixinLocale.fil);
    expect(EmojiWeixinLocale.fromCode('ms'), EmojiWeixinLocale.ms);
    expect(EmojiWeixinLocale.fromCode('hi'), EmojiWeixinLocale.hi);
  });

  test('EmojiWeixinStrings switches by locale', () {
    expect(EmojiWeixinStrings.of(EmojiWeixinLocale.zh).addEditImage, '添加/编辑图片');
    expect(EmojiWeixinStrings.of(EmojiWeixinLocale.en).addEditImage, 'Add / edit image');
    expect(EmojiWeixinStrings.of(EmojiWeixinLocale.vi).addTooltip, 'Thêm');
  });
}
