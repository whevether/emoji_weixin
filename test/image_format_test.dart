import 'dart:typed_data';

import 'package:emoji_weixin/src/network/image_format.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List b(List<int> v) => Uint8List.fromList([...v, ...List.filled(32, 0)]);
List<int> a(String s) => s.codeUnits;

void main() {
  test('detects common raster formats from bytes', () {
    expect(sniffImageExtension(b(a('GIF89a'))), 'gif');
    expect(
      sniffImageExtension(b([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
      'png',
    );
    expect(sniffImageExtension(b([0xff, 0xd8, 0xff, 0xe0])), 'jpg');
    expect(
      sniffImageExtension(
        b([...a('RIFF'), 0, 0, 0, 0, ...a('WEBP'), ...a('VP8 ')]),
      ),
      'webp',
    );
    expect(
      sniffImageExtension(b([...a('BM'), ...List.filled(12, 0), 40, 0, 0, 0])),
      'bmp',
    );
    expect(sniffImageExtension(b([0, 0, 1, 0, 1, 0])), 'ico');
    expect(sniffImageExtension(b([0, 0, 0, 0x18, ...a('ftypavif')])), 'avif');
    expect(sniffImageExtension(b([0, 0, 0, 0x18, ...a('ftypheic')])), 'heic');
    expect(sniffImageExtension(b([0x49, 0x49, 0x2a, 0x00])), 'tiff');
    expect(sniffImageExtension(b(a('<svg xmlns="x"></svg>'))), 'svg');
  });

  test('loose 2 to 4 byte prefixes are not enough', () {
    expect(sniffImageExtension(b(a('BM'))), isNull);
    expect(sniffImageExtension(b([0, 0, 1, 0])), isNull);
    final longDoctype = '<!-- ${'x' * 600} --><svg></svg>';
    expect(sniffImageExtension(b(a(longDoctype))), 'svg');
  });

  test('only displayable formats are renderable', () {
    for (final ext in ['png', 'jpg', 'gif', 'webp', 'bmp', 'ico']) {
      expect(isRenderableExtension(ext), isTrue, reason: ext);
    }
    for (final ext in ['heic', 'tiff', 'jxl', 'svg', null]) {
      expect(isRenderableExtension(ext), isFalse, reason: '$ext');
    }
  });

  test('rejects non-images', () {
    expect(sniffImageExtension(b(a('<html></html>'))), isNull);
  });

  test('detects animated WebP and APNG, but not static ones', () {
    final animatedWebp = b([
      ...a('RIFF'), 0, 0, 0, 0, ...a('WEBP'), ...a('VP8X'),
      10, 0, 0, 0, 0x02, // animation flag
    ]);
    final staticWebp = b([
      ...a('RIFF'),
      0,
      0,
      0,
      0,
      ...a('WEBP'),
      ...a('VP8X'),
      10,
      0,
      0,
      0,
      0x00,
    ]);
    expect(isAnimatedImage(animatedWebp), isTrue);
    expect(isAnimatedImage(staticWebp), isFalse);

    const sig = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    final apng = b([
      ...sig,
      0,
      0,
      0,
      8,
      ...a('acTL'),
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);
    final png = b([
      ...sig, 0, 0, 0, 0, ...a('IDAT'), 0, 0, 0, 0, //
    ]);
    expect(isAnimatedImage(apng), isTrue);
    expect(isAnimatedImage(png), isFalse);
    expect(isAnimatedImage(b(a('GIF89a'))), isTrue);
  });
}
