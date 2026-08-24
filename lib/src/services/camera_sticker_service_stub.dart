import 'package:material_ui/material_ui.dart';

import '../models/sticker.dart';
import 'sticker_edit_helper.dart';

/// Web (and non-IO) path: [FileType.image] may open camera on mobile browsers.
Future<Sticker?> captureAndEdit(BuildContext context) {
  return StickerEditHelper.pickImageEditAndSave(context);
}
