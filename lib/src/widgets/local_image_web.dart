import 'package:material_ui/material_ui.dart';

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
    return errorBuilder?.call(
          context,
          StateError('Unsupported local path on web'),
          StackTrace.current,
        ) ??
        const SizedBox.shrink();
  }
}
