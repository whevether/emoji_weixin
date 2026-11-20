import 'dart:typed_data';

bool _starts(Uint8List b, List<int> sig, [int offset = 0]) {
  if (b.length < offset + sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (b[offset + i] != sig[i]) return false;
  }
  return true;
}

List<int> _ascii(String s) => s.codeUnits;

/// Detects an image format from magic bytes.
///
/// Returns a lowercase file extension (`gif`, `png`, `jpg`, `webp`, `bmp`,
/// `ico`, `avif`, `heic`, `tiff`, `jxl`, `svg`) or `null` when unknown.
String? sniffImageExtension(Uint8List b) {
  if (_starts(b, _ascii('GIF87a')) || _starts(b, _ascii('GIF89a'))) {
    return 'gif';
  }
  if (_starts(b, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return 'png';
  }
  if (_starts(b, [0xff, 0xd8, 0xff])) return 'jpg';
  if (_starts(b, _ascii('RIFF')) && _starts(b, _ascii('WEBP'), 8)) {
    return 'webp';
  }
  if (_starts(b, _ascii('BM')) && b.length >= 30) {
    // The DIB header size at offset 14 must be a known value.
    final dib = b[14] | (b[15] << 8) | (b[16] << 16) | (b[17] << 24);
    if (const {12, 40, 52, 56, 64, 108, 124}.contains(dib)) return 'bmp';
  }
  // ICO: reserved 0, type 1, then a non-zero image count.
  if (_starts(b, [0x00, 0x00, 0x01, 0x00]) &&
      b.length >= 22 &&
      (b[4] | (b[5] << 8)) > 0) {
    return 'ico';
  }
  if (_starts(b, _ascii('ftyp'), 4)) {
    final brand = String.fromCharCodes(
      b.sublist(8, b.length < 12 ? b.length : 12),
    );
    if (brand == 'avif' || brand == 'avis') return 'avif';
    if (const {
      'heic',
      'heix',
      'hevc',
      'hevx',
      'mif1',
      'msf1',
      'heim',
      'heis',
    }.contains(brand)) {
      return 'heic';
    }
  }
  if (_starts(b, [0x49, 0x49, 0x2a, 0x00]) ||
      _starts(b, [0x4d, 0x4d, 0x00, 0x2a])) {
    return 'tiff';
  }
  if (_starts(b, [0xff, 0x0a]) ||
      _starts(b, [0x00, 0x00, 0x00, 0x0c, 0x4a, 0x58, 0x4c, 0x20])) {
    return 'jxl';
  }
  final head = String.fromCharCodes(
    b.sublist(0, b.length < 4096 ? b.length : 4096),
  ).toLowerCase();
  if (head.contains('<svg')) return 'svg';
  return null;
}

/// Formats Flutter's image codec can display. Other sniffed formats (HEIC,
/// TIFF, JPEG XL, SVG) would be stored but render as a broken image.
const renderableImageExtensions = {
  'gif',
  'png',
  'jpg',
  'webp',
  'bmp',
  'ico',
  'avif',
};

/// Whether [extension] (from [sniffImageExtension]) can be displayed.
bool isRenderableExtension(String? extension) =>
    extension != null && renderableImageExtensions.contains(extension);

/// Whether [bytes] hold a multi-frame image (GIF, animated WebP, APNG,
/// animated AVIF). Such files must not go through the static editor.
bool isAnimatedImage(Uint8List b) {
  switch (sniffImageExtension(b)) {
    case 'gif':
      return true;
    case 'webp':
      // VP8X chunk with the animation flag (bit 1) set.
      return b.length > 20 &&
          _starts(b, _ascii('VP8X'), 12) &&
          (b[20] & 0x02) != 0;
    case 'png':
      // APNG: an acTL chunk appears before the first IDAT chunk.
      var i = 8;
      while (i + 8 <= b.length) {
        final len =
            (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
        if (_starts(b, _ascii('acTL'), i + 4)) return true;
        if (_starts(b, _ascii('IDAT'), i + 4)) return false;
        i += 12 + len;
      }
      return false;
    case 'avif':
      return b.length > 12 && String.fromCharCodes(b.sublist(8, 12)) == 'avis';
    default:
      return false;
  }
}
