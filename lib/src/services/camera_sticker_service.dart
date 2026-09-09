import 'package:flutter/widgets.dart';

import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import 'camera_sticker_service_stub.dart'
    if (dart.library.io) 'camera_sticker_service_io.dart' as impl;

class CameraStickerService {
  /// Capture with the system camera, edit with ProImageEditor, save to favorites.
  ///
  /// Available on iOS/Android only; returns `null` on Web/desktop.
  Future<Sticker?> captureAndEdit(
    BuildContext context, {
    required EmojiWeixinStrings strings,
  }) =>
      impl.captureAndEdit(context, strings: strings);
}
