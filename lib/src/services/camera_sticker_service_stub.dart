import 'package:material_ui/material_ui.dart';

import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';

/// Web / non-IO: no system camera entry in the add menu.
Future<Sticker?> captureAndEdit(
  BuildContext context, {
  required EmojiWeixinStrings strings,
}) async =>
    null;
