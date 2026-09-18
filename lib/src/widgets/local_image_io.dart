import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// IO implementation of a local file image via [Image.file].
class LocalFileImage extends StatelessWidget {
  /// Creates a file-backed image for [path].
  const LocalFileImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  /// Absolute filesystem path.
  final String path;

  /// Optional layout width.
  final double? width;

  /// Optional layout height.
  final double? height;

  /// How to inscribe the image into the layout box.
  final BoxFit fit;

  /// Builder shown when decoding fails.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Builds an [Image.file] for [path].
  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
