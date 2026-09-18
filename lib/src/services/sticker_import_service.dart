import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../platform/sticker_storage.dart';
import 'sticker_edit_helper.dart';

/// Imports gallery images into the custom favorites pack.
class StickerImportService {
  /// Creates an import service backed by [StickerRepository.instance] by default.
  StickerImportService({StickerRepository? repository})
      : _repo = repository ?? StickerRepository.instance;

  final StickerRepository _repo;
  final ImagePicker _picker = ImagePicker();

  /// Pick images from the gallery.
  ///
  /// Static images open [ProImageEditor] before save. Animated GIFs cannot be
  /// edited by `pro_image_editor` without losing animation, so they are saved
  /// directly.
  Future<List<Sticker>> pickAndAddCustomStickers(BuildContext context) async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return const [];

    final added = <Sticker>[];
    for (final file in files) {
      if (!context.mounted) break;

      final bytes = await file.readAsBytes();
      if (!context.mounted) break;

      final ext = p.extension(file.name).replaceFirst('.', '').toLowerCase();
      final mime = file.mimeType?.toLowerCase() ?? '';
      final isGif = ext == 'gif' || mime.contains('gif');
      final name = p.basenameWithoutExtension(file.name);

      if (isGif) {
        added.add(
          await _saveCustom(
            bytes: bytes,
            ext: 'gif',
            name: name,
            kind: StickerKind.gif,
          ),
        );
        continue;
      }

      final edited = await StickerEditHelper.editBytes(context, bytes);
      if (edited == null) continue;

      added.add(
        await _saveCustom(
          bytes: edited,
          ext: 'jpg',
          name: name,
          kind: StickerKind.staticImage,
        ),
      );
    }
    return added;
  }

  Future<Sticker> _saveCustom({
    required Uint8List bytes,
    required String ext,
    required String name,
    required StickerKind kind,
  }) async {
    final id = _repo.newId();
    final filename = '$id.$ext';
    final ref = await StickerStorage.saveBytes(
      packId: 'custom',
      filename: filename,
      bytes: bytes,
    );
    return _repo.addStickerToCustom(
      name: name,
      kind: kind,
      localPath: ref,
    );
  }
}
