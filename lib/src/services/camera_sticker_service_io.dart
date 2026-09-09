import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../platform/platform_caps.dart';
import 'sticker_edit_helper.dart';

Future<Sticker?> captureAndEdit(
  BuildContext context, {
  required EmojiWeixinStrings strings,
}) async {
  if (!PlatformCaps.supportsMobileCamera) return null;

  final photo = await ImagePicker().pickImage(source: ImageSource.camera);
  if (photo == null || !context.mounted) return null;

  final bytes = await photo.readAsBytes();
  if (!context.mounted) return null;
  return StickerEditHelper.editBytesAndSave(context, bytes, strings: strings);
}
