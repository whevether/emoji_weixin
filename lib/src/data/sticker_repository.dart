import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/sticker_storage.dart';
import 'douyin_sticker_catalog.dart';

class StickerRepository {
  StickerRepository._();

  static final StickerRepository instance = StickerRepository._();

  static const _boxName = 'emoji_weixin_packs';
  static const _customPackId = 'custom';
  static const _legacyBuiltinPackId = 'builtin_default';
  static const _recentKey = '_recent_stickers';
  static const _maxRecent = 24;

  final _uuid = const Uuid();
  Box<String>? _box;

  Future<void> init() async {
    if (_box != null) return;
    await Hive.initFlutter();
    await StickerStorage.init();
    _box = await Hive.openBox<String>(_boxName);
    // Remove legacy image-based "默认表情" pack if present.
    await _box!.delete(_legacyBuiltinPackId);
    await _ensureDouyinPack();
    await _ensureCustomPack();
  }

  /// Back-compat for callers that previously used filesystem pack dirs.
  String packDir(String packId) => '${StickerStorage.rootHint()}/packs/$packId';

  Future<void> _ensureDouyinPack() async {
    try {
      final pack = await DouyinStickerCatalog.loadPack();
      if (pack.stickers.isEmpty) return;
      await savePack(pack);
    } catch (_) {
      // Assets missing in some test contexts; ignore.
    }
  }

  Future<void> _ensureCustomPack() async {
    if (_box!.containsKey(_customPackId)) return;
    await savePack(
      const StickerPack(
        id: _customPackId,
        name: '收藏',
        source: StickerSource.custom,
        stickers: [],
      ),
    );
  }

  List<Sticker> getRecentStickers() {
    final raw = _box!.get(_recentKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Sticker.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> recordRecent(Sticker sticker) async {
    final next = <Sticker>[sticker];
    for (final item in getRecentStickers()) {
      if (item.id == sticker.id) continue;
      next.add(item);
      if (next.length >= _maxRecent) break;
    }
    await _box!.put(
      _recentKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  List<StickerPack> getAllPacks() {
    final packs = _box!.values
        .map((raw) {
          try {
            return StickerPack.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<StickerPack>()
        .where((p) => p.id != _recentKey && !p.id.startsWith('_'))
        .toList();
    packs.sort((a, b) {
      int rank(String id, StickerSource s) {
        if (id == DouyinStickerCatalog.packId) return 0;
        return switch (s) {
          StickerSource.builtin => 1,
          StickerSource.custom => 2,
          StickerSource.imported => 3,
          StickerSource.giphy => 4,
        };
      }

      final c = rank(a.id, a.source).compareTo(rank(b.id, b.source));
      if (c != 0) return c;
      return a.name.compareTo(b.name);
    });
    return packs;
  }

  StickerPack? getPack(String id) {
    final raw = _box!.get(id);
    if (raw == null) return null;
    try {
      return StickerPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  StickerPack get customPack =>
      getPack(_customPackId) ??
      const StickerPack(
        id: _customPackId,
        name: '收藏',
        source: StickerSource.custom,
      );

  Future<void> savePack(StickerPack pack) async {
    await _box!.put(pack.id, jsonEncode(pack.toJson()));
  }

  Future<void> deletePack(String packId) async {
    if (packId == _customPackId || packId == DouyinStickerCatalog.packId) {
      throw ArgumentError('Cannot delete system pack: $packId');
    }
    await StickerStorage.deletePackDir(packId);
    await _box!.delete(packId);
  }

  Future<Sticker> addStickerToCustom({
    required String name,
    required StickerKind kind,
    required String localPath,
    String? networkUrl,
  }) async {
    final pack = customPack;
    final sticker = Sticker(
      id: _uuid.v4(),
      packId: pack.id,
      name: name,
      kind: kind,
      localPath: localPath,
      networkUrl: networkUrl,
      createdAt: DateTime.now(),
    );
    final updated = pack.copyWith(
      stickers: [...pack.stickers, sticker],
      coverPath: pack.coverPath ?? localPath,
    );
    await savePack(updated);
    return sticker;
  }

  Future<void> removeSticker(String packId, String stickerId) async {
    final pack = getPack(packId);
    if (pack == null) return;
    final next = pack.stickers.where((s) => s.id != stickerId).toList();
    await savePack(pack.copyWith(stickers: next));
  }

  Future<StickerPack> renamePack(String packId, String name) async {
    final pack = getPack(packId);
    if (pack == null) {
      throw StateError('Pack not found: $packId');
    }
    final updated = pack.copyWith(name: name);
    await savePack(updated);
    return updated;
  }

  String newId() => _uuid.v4();
}
