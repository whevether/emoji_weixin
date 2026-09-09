import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../data/sticker_repository.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../platform/sticker_storage.dart';

/// Edit helpers. [pro_image_editor] does not preserve animated GIF — callers
/// should skip editing for [StickerKind.gif] and save bytes as-is.
abstract final class StickerEditHelper {
  /// Open [ProImageEditor]; returns edited bytes or `null` if cancelled.
  static Future<Uint8List?> editBytes(
    BuildContext context,
    Uint8List bytes,
  ) async {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (ctx) => MaterialUiCompatibilityBridge( // ignore: deprecated_member_use
          child: ProImageEditor.memory(
            bytes,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (out) async {
                Navigator.of(ctx).pop(out);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Edit then save into favorites (static image / camera capture).
  static Future<Sticker?> editBytesAndSave(
    BuildContext context,
    Uint8List bytes, {
    required EmojiWeixinStrings strings,
  }) async {
    final edited = await editBytes(context, bytes);
    if (edited == null) return null;

    final repo = StickerRepository.instance;
    final id = repo.newId();
    final ref = await StickerStorage.saveBytes(
      packId: 'custom',
      filename: '$id.jpg',
      bytes: edited,
    );

    return repo.addStickerToCustom(
      name: strings.photoStickerName,
      kind: StickerKind.staticImage,
      localPath: ref,
    );
  }
}
