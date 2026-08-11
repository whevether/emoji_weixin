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
    expect(StickerKind.fromExtension('json'), StickerKind.lottie);
    expect(StickerKind.fromExtension('png'), StickerKind.staticImage);
  });
}
