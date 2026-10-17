import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../platform/sticker_storage.dart';
import 'local_image_web.dart'
    if (dart.library.io) 'local_image_io.dart'
    as platform;

/// Renders a sticker local ref (filesystem path or `hive:` blob key).
class LocalImage extends StatefulWidget {
  /// Creates a local / blob image widget for [ref].
  const LocalImage({
    super.key,
    required this.ref,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  /// Filesystem path or `hive:` storage key.
  final String ref;

  /// Optional layout width.
  final double? width;

  /// Optional layout height.
  final double? height;

  /// How to inscribe the image into the layout box.
  final BoxFit fit;

  /// Builder shown when decoding fails.
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<LocalImage> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ref != widget.ref) _load();
  }

  void _load() {
    _bytes = StickerStorage.isBlobRef(widget.ref)
        ? StickerStorage.readBytes(widget.ref)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final ref = widget.ref;
    final width = widget.width;
    final height = widget.height;
    final fit = widget.fit;
    final errorBuilder = widget.errorBuilder;
    if (StickerStorage.isBlobRef(ref)) {
      return FutureBuilder<Uint8List?>(
        key: ValueKey(ref),
        future: _bytes,
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
                  snap.error ?? StateError('missing blob'),
                  snap.stackTrace ?? StackTrace.current,
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
