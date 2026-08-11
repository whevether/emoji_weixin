import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/sticker_storage.dart';
import 'local_image_io.dart' if (dart.library.html) 'local_image_web.dart'
    as platform;

/// Renders a sticker local ref (filesystem path or `hive:` blob key).
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.ref,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  final String ref;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (StickerStorage.isBlobRef(ref)) {
      return FutureBuilder<Uint8List?>(
        future: StickerStorage.readBytes(ref),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return errorBuilder?.call(
                  context,
                  StateError('missing blob'),
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
    return platform.LocalFileImage(
      path: ref,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
