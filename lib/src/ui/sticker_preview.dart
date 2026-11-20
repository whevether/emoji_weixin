import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../data/sticker_repository.dart';
import '../klipy/klipy_sticker_service.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../widgets/sticker_renderer.dart';

/// Adds [sticker] to the favorites pack. Returns `false` when it is not
/// favoritable (unicode emoji) or already present.
Future<bool> addStickerToFavorites(Sticker sticker) async {
  if (sticker.kind == StickerKind.unicode) return false;
  final repo = StickerRepository.instance;
  await repo.init();
  final existing = repo.customPack.stickers;
  final url = sticker.networkUrl;
  final local = sticker.localPath;
  final asset = sticker.assetPath;
  if (local != null) {
    if (sticker.packId == repo.customPack.id) return false;
    if (existing.any((s) => s.localPath == local)) return false;
    await repo.addStickerToCustom(
      name: sticker.name,
      kind: sticker.kind,
      localPath: local,
      networkUrl: url,
    );
    return true;
  }
  if (asset != null) {
    final data = await rootBundle.load('packages/emoji_weixin/$asset');
    final ext = p.extension(asset).replaceFirst('.', '').toLowerCase();
    final before = existing.map((s) => s.id).toSet();
    final saved = await repo.saveCustomBytes(
      name: sticker.name,
      kind: sticker.kind,
      bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      extension: ext.isEmpty ? 'png' : ext,
    );
    // Identical content is deduplicated and returns the existing sticker.
    return !before.contains(saved.id);
  }
  if (url != null && url.isNotEmpty) {
    if (existing.any((s) => s.networkUrl == url)) return false;
    final service = KlipyStickerService();
    try {
      await service.saveStickerToFavorite(sticker);
    } finally {
      service.close();
    }
    return true;
  }
  return false;
}

/// Shows a large preview with send / add-to-favorites actions.
Future<void> showStickerPreview(
  BuildContext context, {
  required Sticker sticker,
  required EmojiWeixinStrings strings,
  required void Function(Sticker sticker) onSend,
  VoidCallback? onFavorited,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: SizedBox(
        width: 200,
        height: 200,
        child: StickerRenderer(sticker: sticker, width: 200, height: 200),
      ),
      actions: [
        if (sticker.kind != StickerKind.unicode)
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              Navigator.pop(ctx);
              try {
                final repo = StickerRepository.instance;
                await repo.init();
                if (repo.isFavoritesFull) {
                  messenger?.showSnackBar(
                    SnackBar(content: Text(strings.favoritesFull)),
                  );
                  return;
                }
                final added = await addStickerToFavorites(sticker);
                if (added) onFavorited?.call();
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? strings.addedToFavorites
                          : strings.alreadyInFavorites,
                    ),
                  ),
                );
              } catch (error) {
                messenger?.showSnackBar(
                  SnackBar(content: Text(strings.operationFailed(error))),
                );
              }
            },
            child: Text(strings.addToFavorites),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onSend(sticker);
          },
          child: Text(strings.send),
        ),
      ],
    ),
  );
}
