import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../network/image_format.dart';
import 'sticker_edit_helper.dart';

/// Imports gallery images into the custom favorites pack.
class StickerImportService {
  /// Creates an import service backed by [StickerRepository.instance] by default.
  StickerImportService({StickerRepository? repository})
    : _repo = repository ?? StickerRepository.instance;

  /// Static formats Flutter can decode, so the editor can open them.
  static const _editable = {'png', 'jpg', 'webp', 'bmp', 'ico'};

  final StickerRepository _repo;
  final ImagePicker _picker = ImagePicker();

  /// Pick images from the gallery.
  ///
  /// Static images open [ProImageEditor] before save. Animated GIFs cannot be
  /// edited by `pro_image_editor` without losing animation, so they are saved
  /// directly.
  Future<List<Sticker>> pickAndAddCustomStickers(BuildContext context) async {
    await _repo.init();
    if (!context.mounted) return const [];
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return const [];

    final added = <Sticker>[];
    // Already-saved media is returned as-is by the repository; only count
    // stickers that are genuinely new.
    final known = _repo.customPack.stickers.map((s) => s.id).toSet();
    Future<void> save(Future<Sticker> Function() action) async {
      final sticker = await action();
      if (known.add(sticker.id)) added.add(sticker);
    }

    try {
      for (final file in files) {
        if (!context.mounted || _repo.isFavoritesFull) break;

        final bytes = await file.readAsBytes();
        if (!context.mounted) break;

        final name = p.basenameWithoutExtension(file.name);
        // Sniff real content: names and MIME types can be wrong or missing.
        final sniffed = sniffImageExtension(bytes);
        // Formats Flutter cannot display would only become broken stickers.
        if (!isRenderableExtension(sniffed)) continue;

        // Animated files (GIF, animated WebP, APNG, animated AVIF) and formats
        // the editor cannot decode are stored untouched.
        if (isAnimatedImage(bytes) || !_editable.contains(sniffed)) {
          await save(
            () => _repo.saveCustomBytes(
              bytes: bytes,
              extension: sniffed!,
              name: name,
              kind: isAnimatedImage(bytes)
                  ? StickerKind.gif
                  : StickerKind.staticImage,
            ),
          );
          continue;
        }

        final edited = await StickerEditHelper.editBytes(context, bytes);
        if (edited == null) continue;
        if (_repo.isFavoritesFull) break;

        await save(
          () => _repo.saveCustomBytes(
            bytes: edited,
            extension: 'png',
            name: name,
            kind: StickerKind.staticImage,
          ),
        );
      }
    } catch (_) {
      // Keep what was already saved instead of losing the whole batch.
      if (added.isEmpty) rethrow;
    }
    return added;
  }
}
