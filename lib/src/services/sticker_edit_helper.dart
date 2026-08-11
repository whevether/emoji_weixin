import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../platform/sticker_storage.dart';

/// Shared pick → edit → save helpers (works on Web / desktop / mobile).
abstract final class StickerEditHelper {
  /// Pick an image via [FileType.image] (Web may offer camera), then edit.
  static Future<Sticker?> pickImageEditAndSave(BuildContext context) async {
    final file = await FilePicker.pickFile(
      dialogTitle: '拍照或选择图片',
      type: FileType.image,
    );
    if (file == null || !context.mounted) return null;

    final bytes = await file.xFile.readAsBytes();
    if (!context.mounted) return null;
    return editBytesAndSave(context, bytes);
  }

  /// Open [ProImageEditor] on [bytes], then save into favorites.
  static Future<Sticker?> editBytesAndSave(
    BuildContext context,
    Uint8List bytes,
  ) async {
    final edited = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (ctx) => ProImageEditor.memory(
          bytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (out) async {
              Navigator.of(ctx).pop(out);
            },
          ),
        ),
      ),
    );
    if (edited == null) return null;

    final repo = StickerRepository.instance;
    final id = repo.newId();
    final ref = await StickerStorage.saveBytes(
      packId: 'custom',
      filename: '$id.jpg',
      bytes: edited,
    );

    return repo.addStickerToCustom(
      name: '拍照表情',
      kind: StickerKind.staticImage,
      localPath: ref,
    );
  }
}
