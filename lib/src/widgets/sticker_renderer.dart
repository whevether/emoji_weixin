import 'package:material_ui/material_ui.dart';

import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import 'local_image.dart';

/// Renders PNG/JPG/WebP, GIF, or unicode emoji stickers.
class StickerRenderer extends StatelessWidget {
  const StickerRenderer({
    super.key,
    required this.sticker,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final Sticker sticker;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (sticker.kind == StickerKind.unicode && sticker.unicode != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            sticker.unicode!,
            style: TextStyle(fontSize: (width ?? height ?? 40) * 0.72),
          ),
        ),
      );
    }

    return _buildImage();
  }

  Widget _buildImage() {
    final w = width;
    final h = height;
    if (sticker.localPath != null) {
      return LocalImage(
        ref: sticker.localPath!,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    if (sticker.assetPath != null) {
      return Image.asset(
        sticker.assetPath!,
        package: 'emoji_weixin',
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    if (sticker.networkUrl != null) {
      return Image.network(
        sticker.networkUrl!,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(
        color: Color(0xFFEDEDED),
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace) {
    return _placeholder();
  }
}
