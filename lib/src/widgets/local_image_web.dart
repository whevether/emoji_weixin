import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/sticker_storage.dart';

class LocalFileImage extends StatelessWidget {
  const LocalFileImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

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
