import 'dart:convert';

import 'package:tostore/tostore.dart';
import 'package:uuid/uuid.dart';

import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/sticker_storage.dart';
import 'douyin_sticker_catalog.dart';
import 'emoji_store.dart';

/// Persistent sticker packs, favorites, and recently-used history (ToStore KV).
class StickerRepository {
  StickerRepository._();

  /// Shared singleton used by the panel and services.
  static final StickerRepository instance = StickerRepository._();

  static const _customPackId = 'custom';
  static const _legacyBuiltinPackId = 'builtin_default';
  static const _recentKey = '_recent_stickers';
  static const _maxRecent = 24;
  static const _pageSize = 200;

  final _uuid = const Uuid();

  /// In-memory copy of the KV space so pack reads stay synchronous.
  Map<String, String>? _values;

  /// Opens ToStore / storage and ensures system packs exist.
  Future<void> init() async {
    if (_values != null) return;
    final db = await EmojiStore.instance.open();
    await StickerStorage.init();
    _values = await _readAll(db);
    if (_values!.containsKey(_legacyBuiltinPackId)) {
      await db.removeValue(_legacyBuiltinPackId);
      _values!.remove(_legacyBuiltinPackId);
    }
    await _ensureDouyinPack();
    await _ensureCustomPack();
  }

  Map<String, String> get _ensureValues {
    final values = _values;
    if (values == null) {
      throw StateError('StickerRepository not initialized');
    }
    return values;
  }

  /// Loads every KV record. [getAllPacks] filters this snapshot.
  Future<Map<String, String>> _readAll(ToStore db) async {
    final values = <String, String>{};
    var page = await db.kv.query().limit(_pageSize);
    while (true) {
      for (final record in page.data) {
        final key = record['key'];
        final raw = _asString(record['value']);
        if (key is String && raw != null) values[key] = raw;
      }
      if (!page.hasMore) break;
      final next = await page.next();
      if (next.data.isEmpty) break;
      page = next;
    }
    return values;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return jsonEncode(value);
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
    if (_ensureValues.containsKey(_customPackId)) return;
    await savePack(
      const StickerPack(
        id: _customPackId,
        name: '收藏',
        source: StickerSource.custom,
        stickers: [],
      ),
    );
  }

  /// Returns the recently used stickers list (most recent first).
  List<Sticker> getRecentStickers() {
    final raw = _ensureValues[_recentKey];
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

  /// Records [sticker] as most recently used (capped list).
  Future<void> recordRecent(Sticker sticker) async {
    final next = <Sticker>[sticker];
    for (final item in getRecentStickers()) {
      if (item.id == sticker.id) continue;
      next.add(item);
      if (next.length >= _maxRecent) break;
    }
    await _put(
      _recentKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  /// All user-visible packs, sorted by source then name.
  List<StickerPack> getAllPacks() {
    final packs = _ensureValues.values
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
          StickerSource.klipy => 4,
        };
      }

      final c = rank(a.id, a.source).compareTo(rank(b.id, b.source));
      if (c != 0) return c;
      return a.name.compareTo(b.name);
    });
    return packs;
  }

  /// Looks up a pack by [id], or `null` if missing / corrupt.
  StickerPack? getPack(String id) {
    final raw = _ensureValues[id];
    if (raw == null) return null;
    try {
      return StickerPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// The user favorites pack (`custom`).
  StickerPack get customPack =>
      getPack(_customPackId) ??
      const StickerPack(
        id: _customPackId,
        name: '收藏',
        source: StickerSource.custom,
      );

  /// Persists [pack] to ToStore.
  Future<void> savePack(StickerPack pack) async {
    await _put(pack.id, jsonEncode(pack.toJson()));
  }

  Future<void> _put(String key, String raw) async {
    await EmojiStore.instance.db.setValue(key, raw);
    _ensureValues[key] = raw;
  }

  /// Deletes a non-system pack and its stored media.
  Future<void> deletePack(String packId) async {
    if (packId == _customPackId || packId == DouyinStickerCatalog.packId) {
      throw ArgumentError('Cannot delete system pack: $packId');
    }
    await StickerStorage.deletePackDir(packId);
    await EmojiStore.instance.db.removeValue(packId);
    _ensureValues.remove(packId);
  }

  /// Appends a sticker to the favorites pack and returns it.
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

  /// Removes a sticker from [packId] by [stickerId].
  Future<void> removeSticker(String packId, String stickerId) async {
    final pack = getPack(packId);
    if (pack == null) return;
    final next = pack.stickers.where((s) => s.id != stickerId).toList();
    await savePack(pack.copyWith(stickers: next));
  }

  /// Renames a pack and returns the updated pack.
  Future<StickerPack> renamePack(String packId, String name) async {
    final pack = getPack(packId);
    if (pack == null) {
      throw StateError('Pack not found: $packId');
    }
    final updated = pack.copyWith(name: name);
    await savePack(updated);
    return updated;
  }

  /// Generates a new UUID string for sticker / file ids.
  String newId() => _uuid.v4();
}
