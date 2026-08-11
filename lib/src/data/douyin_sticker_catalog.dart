import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';

/// Built-in Douyin sticker pack loaded from bundled assets
/// (sourced from https://github.com/hnlyzxf/douyin-emoji for learning only).
class DouyinStickerCatalog {
  DouyinStickerCatalog._();

  static const packId = 'builtin_douyin';
  static const _infoAsset =
      'packages/emoji_weixin/assets/stickers/douyin/info.json';
  static const _infoAssetFallback = 'assets/stickers/douyin/info.json';
  static const _staticPrefix = 'assets/stickers/douyin/static/';

  static Future<StickerPack> loadPack() async {
    final raw = await _loadInfoJson();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = json['stickers'] as List<dynamic>? ?? const [];

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest.listAssets().toSet();

    final stickers = <Sticker>[];
    final seen = <String>{};
    for (final item in list) {
      final map = Map<String, dynamic>.from(item as Map);
      final uri = map['uri'] as String?;
      if (uri == null || uri.isEmpty || !seen.add(uri)) continue;

      final assetPath = '$_staticPrefix$uri';
      final packaged = 'packages/emoji_weixin/$assetPath';
      if (!available.contains(assetPath) && !available.contains(packaged)) {
        continue;
      }

      final showName = (map['show_name'] as String?)?.trim();
      final displayName = (map['display_name'] as String?)?.trim();
      final name = (showName != null && showName.isNotEmpty)
          ? showName
          : (displayName != null && displayName.isNotEmpty)
              ? displayName.replaceAll(RegExp(r'^\[|\]$'), '')
              : uri;

      stickers.add(
        Sticker(
          id: 'douyin_$uri',
          packId: packId,
          name: name,
          kind: StickerKind.staticImage,
          assetPath: assetPath,
        ),
      );
    }

    final cover = json['mini_cover'] as String?;
    final coverAsset = cover != null && cover.isNotEmpty
        ? '$_staticPrefix$cover'
        : (stickers.isNotEmpty ? stickers.first.assetPath : null);

    return StickerPack(
      id: packId,
      name: '抖音表情',
      source: StickerSource.builtin,
      coverAsset: coverAsset,
      stickers: stickers,
    );
  }

  static Future<String> _loadInfoJson() async {
    try {
      return await rootBundle.loadString(_infoAsset);
    } catch (_) {
      return rootBundle.loadString(_infoAssetFallback);
    }
  }
}
