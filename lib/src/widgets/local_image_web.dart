import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../platform/sticker_storage.dart';

/// Web / WASM local image: reads bytes via [StickerStorage] then [Image.memory].
class LocalFileImage extends StatelessWidget {
  /// Creates a storage-backed image for [path] (usually a `hive:` ref).
  const LocalFileImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  /// Storage ref or path; filesystem paths are unsupported on web.
  final String path;

  /// Optional layout width.
  final double? width;

  /// Optional layout height.
  final double? height;

  /// How to inscribe the image into the layout box.
  final BoxFit fit;

  /// Builder shown when decoding fails.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Loads bytes asynchronously and builds [Image.memory].
  @override
  Widget build(BuildContext context) {
    // On web, custom stickers should use hive: refs; fall back to storage read.
    return FutureBuilder<Uint8List?>(
      future: StickerStorage.readBytes(path),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return errorBuilder?.call(
                context,
                StateError('unsupported local path on web'),
                StackTrace.current,
              ) ??
              const SizedBox.shrink();
        }
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
