import 'package:flutter/widgets.dart';

import '../models/sticker.dart';
import 'camera_sticker_service_stub.dart'
    if (dart.library.io) 'camera_sticker_service_io.dart' as impl;

class CameraStickerService {
  /// Capture/pick an image, edit with ProImageEditor, save to favorites.
  ///
  /// - iOS/Android: WeChat-style camera picker
  /// - Web/desktop: [FileType.image] (Web may offer device camera)
  Future<Sticker?> captureAndEdit(BuildContext context) =>
      impl.captureAndEdit(context);
}
