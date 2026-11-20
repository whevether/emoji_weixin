import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tostore/tostore.dart';
import 'package:uuid/uuid.dart';

import '../network/image_format.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/sticker_storage.dart';
import '../platform/storage_names.dart';
import 'database_result.dart';
import 'douyin_sticker_catalog.dart';
import 'emoji_store.dart';

/// Persistent sticker packs, favorites, and recently-used history.
class StickerRepository {
  StickerRepository._();

  /// Isolated repository with an injected database and optional asset loader.
  @visibleForTesting
  StickerRepository.forTesting({
    required ToStore this._database,
    this._loadBuiltinPack,
  });

  /// Shared singleton used by the panel and services.
  static final StickerRepository instance = StickerRepository._();

  static const _customPackId = 'custom';
  static const _recentKey = '_recent_stickers';
  static const _legacyBuiltinPackId = 'builtin_default';
  static const _maxRecent = 24;

  /// Maximum number of stickers in the favorites pack.
  ///
  /// Hosts may change this once at startup (see
  /// `EmojiWeixinConfig.maxFavorites`).
  static int maxCustomStickers = 300;
  final _uuid = const Uuid();
  ToStore? _database;
  Future<StickerPack?> Function()? _loadBuiltinPack;
  Future<void>? _initializing;
  Future<void> _pending = Future.value();
  bool _initialized = false;
  Map<String, String>? _values;
  final _packs = <String, StickerPack?>{};
  List<StickerPack>? _sortedPacks;
  List<Sticker>? _recent;

  ToStore get _db => _database ?? EmojiStore.instance.db;
  Map<String, String> get _ensureValues =>
      _values ?? (throw StateError('StickerRepository not initialized'));

  /// Opens storage once; simultaneous callers await the same initialization.
  Future<void> init() {
    if (_initialized) return Future.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      _database ??= await EmojiStore.instance.open();
      await StickerStorage.init();
      _values = await _readAll();
      if (_ensureValues.containsKey(_legacyBuiltinPackId)) {
        await _commit(const {}, remove: {_legacyBuiltinPackId});
      }
      StickerPack? builtin;
      if (_loadBuiltinPack != null) {
        builtin = await _loadBuiltinPack!();
      } else {
        try {
          builtin = await DouyinStickerCatalog.loadPack();
        } on FlutterError {
          // Hosts without bundled package assets can still use custom packs.
        }
      }
      if (builtin != null && builtin.stickers.isNotEmpty) {
        await _savePack(builtin);
      }
      if (!_ensureValues.containsKey(_customPackId)) {
        await _savePack(
          const StickerPack(
            id: _customPackId,
            name: '收藏',
            source: StickerSource.custom,
          ),
        );
      }
      _initialized = true;
    } catch (_) {
      _values = null;
      _invalidate();
      rethrow;
    } finally {
      _initializing = null;
    }
  }

  Future<Map<String, String>> _readAll() async {
    final values = <String, String>{};
    var page = await _db.kv.query().limit(200);
    while (true) {
      if (page.hasErrors) throw StateError('Read sticker packs failed');
      for (final record in page.data) {
        final key = record['key'];
        final value = record['value'];
        if (key is String && value != null) {
          values[key] = value is String ? value : jsonEncode(value);
        }
      }
      if (!page.hasMore) break;
      page = await page.next();
    }
    return values;
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    await init();
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  void _invalidate() {
    _packs.clear();
    _sortedPacks = null;
    _recent = null;
  }

  // Publish changes to memory only after the whole database operation commits.
  Future<void> _commit(
    Map<String, String> values, {
    Set<String> remove = const {},
  }) async {
    Future<void> write() async {
      for (final entry in values.entries) {
        requireDatabaseSuccess(
          await _db.setValue(entry.key, entry.value),
          'Save stickers',
        );
      }
      for (final key in remove) {
        requireDatabaseSuccess(
          await _db.removeValue(key),
          'Delete sticker pack',
        );
      }
    }

    if (values.length + remove.length == 1) {
      await write();
    } else {
      final result = await _db.transaction(write);
      if (result.hasErrors) throw StateError('Sticker transaction failed');
    }
    _ensureValues
      ..addAll(values)
      ..removeWhere((key, _) => remove.contains(key));
    for (final key in {...values.keys, ...remove}) {
      if (key == _recentKey) {
        _recent = null;
      } else {
        _packs.remove(key);
        _sortedPacks = null;
      }
    }
  }

  /// Legacy filesystem hint. Use media references on individual stickers.
  @Deprecated('Use Sticker.localPath instead; web storage has no directories')
  String packDir(String packId) {
    validateStorageName(packId, label: 'packId');
    return '${StickerStorage.rootHint()}/packs/$packId';
  }

  /// Returns an immutable recently-used snapshot, most recent first.
  List<Sticker> getRecentStickers() {
    _ensureValues;
    return _recent ??= _decodeRecent();
  }

  List<Sticker> _decodeRecent() {
    final raw = _ensureValues[_recentKey];
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return List.unmodifiable(
        list.map((e) => Sticker.fromJson(Map<String, dynamic>.from(e as Map))),
      );
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  /// Records a sticker without losing concurrent updates.
  Future<void> recordRecent(Sticker sticker) => _mutate(() async {
    final next = [
      sticker,
      ...getRecentStickers().where(
        (s) => s.id != sticker.id || s.packId != sticker.packId,
      ),
    ].take(_maxRecent);
    await _commit({_recentKey: _encodeRecent(next)});
  });

  String _encodeRecent(Iterable<Sticker> stickers) =>
      jsonEncode(stickers.map((s) => s.toJson()).toList());

  /// Cached, immutable packs sorted by source and display name.
  List<StickerPack> getAllPacks() {
    return _sortedPacks ??= List.unmodifiable(
      _ensureValues.keys
          .where((id) => !id.startsWith('_'))
          .map(getPack)
          .whereType<StickerPack>()
          .toList()
        ..sort((a, b) {
          int rank(StickerPack p) =>
              p.id == DouyinStickerCatalog.packId ? -1 : p.source.index;
          final order = rank(a).compareTo(rank(b));
          return order != 0 ? order : a.name.compareTo(b.name);
        }),
    );
  }

  /// Looks up a cached pack, or null when missing or corrupt.
  StickerPack? getPack(String id) {
    if (_packs.containsKey(id)) return _packs[id];
    final raw = _ensureValues[id];
    if (raw == null || id.startsWith('_')) return null;
    try {
      return _packs[id] = StickerPack.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return _packs[id] = null;
    } on TypeError {
      return _packs[id] = null;
    }
  }

  /// User favorites; corrupt data is never silently overwritten by an empty pack.
  StickerPack get customPack =>
      getPack(_customPackId) ??
      (throw StateError('Favorites pack is missing or corrupt'));

  /// Loads the media bytes of [sticker] so a host can upload or forward it.
  ///
  /// Works for stored (including Web `hive:` refs) and bundled stickers.
  /// Returns `null` for unicode emoji and network-only stickers, which the
  /// host must fetch from [Sticker.networkUrl] itself.
  Future<Uint8List?> readStickerBytes(Sticker sticker) async {
    final local = sticker.localPath;
    if (local != null) {
      await init();
      return StickerStorage.readBytes(local);
    }
    final asset = sticker.assetPath;
    if (asset != null) {
      final data = await rootBundle.load('packages/emoji_weixin/$asset');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return null;
  }

  /// Whether favorites have reached [maxCustomStickers].
  bool get isFavoritesFull => customPack.stickers.length >= maxCustomStickers;

  /// Saves a pack, taking a serialized snapshot of its stickers.
  Future<void> savePack(StickerPack pack) => _mutate(() => _savePack(pack));

  Future<void> _savePack(StickerPack pack) async {
    validateStorageName(pack.id, label: 'packId');
    if (pack.id.startsWith('_')) throw ArgumentError('Reserved pack id');
    await _commit({pack.id: jsonEncode(pack.toJson())});
  }

  /// Saves media and its favorite together, removing the new media on failure.
  Future<Sticker> saveCustomBytes({
    required String name,
    required StickerKind kind,
    required Uint8List bytes,
    required String extension,
    String? networkUrl,
  }) => _mutate(() async {
    validateStorageName(extension, label: 'extension');
    if (bytes.isEmpty) throw ArgumentError('Empty sticker media');
    final hash = sha256.convert(bytes).toString();
    for (final existing in customPack.stickers) {
      // Identical content is never stored twice; return the saved sticker.
      if (existing.contentHash == hash) return existing;
    }
    final ref = await StickerStorage.saveBytes(
      packId: _customPackId,
      filename: '${newId()}.$extension',
      bytes: bytes,
    );
    try {
      return await _addCustom(
        name: name,
        kind: kind,
        localPath: ref,
        networkUrl: networkUrl,
        contentHash: hash,
      );
    } catch (error, stack) {
      try {
        await StickerStorage.deleteBytes(ref);
      } catch (cleanupError, cleanupStack) {
        debugPrint(
          'Failed to clean up unsaved sticker: $cleanupError\n$cleanupStack',
        );
      }
      Error.throwWithStackTrace(error, stack);
    }
  });

  /// Appends an existing media reference to favorites.
  Future<Sticker> addStickerToCustom({
    required String name,
    required StickerKind kind,
    required String localPath,
    String? networkUrl,
  }) => _mutate(
    () => _addCustom(
      name: name,
      kind: kind,
      localPath: localPath,
      networkUrl: networkUrl,
    ),
  );

  Future<Sticker> _addCustom({
    required String name,
    required StickerKind kind,
    required String localPath,
    String? networkUrl,
    String? contentHash,
  }) async {
    final pack = customPack;
    if (pack.stickers.length >= maxCustomStickers) {
      throw StateError('Favorites are full ($maxCustomStickers)');
    }
    final sticker = Sticker(
      id: newId(),
      packId: pack.id,
      name: name,
      kind: kind,
      localPath: localPath,
      networkUrl: networkUrl,
      contentHash: contentHash,
      createdAt: DateTime.now(),
    );
    await _savePack(
      pack.copyWith(
        stickers: [...pack.stickers, sticker],
        coverPath: pack.coverPath ?? localPath,
      ),
    );
    return sticker;
  }

  Set<String> _mediaRefs(StickerPack pack) => {
    if (pack.coverPath != null) pack.coverPath!,
    for (final sticker in pack.stickers)
      if (sticker.localPath != null) sticker.localPath!,
  };

  Set<String> _referencedMedia() => {
    for (final pack in getAllPacks()) ..._mediaRefs(pack),
    for (final sticker in getRecentStickers())
      if (sticker.localPath != null) sticker.localPath!,
  };

  Future<void> _cleanUnused(Iterable<String> refs) async {
    final referenced = _referencedMedia();
    for (final ref in refs.toSet().difference(referenced)) {
      // Legacy callers may use paths outside storage. Never delete their files.
      if (!StickerStorage.isBlobRef(ref) &&
          !ref
              .replaceAll('\\', '/')
              .startsWith(
                '${StickerStorage.rootHint().replaceAll('\\', '/')}/packs/',
              )) {
        continue;
      }
      await StickerStorage.deleteBytes(ref);
    }
  }

  /// Deletes a user pack, pruning history and only media no other pack uses.
  Future<void> deletePack(String packId) => _mutate(() async {
    validateStorageName(packId, label: 'packId');
    final pack = getPack(packId);
    if (packId == _customPackId ||
        pack?.source == StickerSource.builtin ||
        packId == DouyinStickerCatalog.packId) {
      throw ArgumentError('Cannot delete system pack');
    }
    if (pack == null) return;
    final recent = getRecentStickers().where((s) => s.packId != packId);
    await _commit({_recentKey: _encodeRecent(recent)}, remove: {packId});
    await _cleanUnused(_mediaRefs(pack));
    final prefix = StickerStorage.rootHint() == 'hive'
        ? 'hive:$packId/'
        : '${StickerStorage.rootHint().replaceAll('\\', '/')}/packs/$packId/';
    if (!_referencedMedia().any(
      (ref) => ref.replaceAll('\\', '/').startsWith(prefix),
    )) {
      await StickerStorage.deletePackDir(packId);
    }
  });

  /// Removes a sticker, refreshing its cover and pruning history and media.
  Future<void> removeSticker(String packId, String stickerId) =>
      _mutate(() async {
        final pack = getPack(packId);
        if (pack == null) return;
        if (pack.source == StickerSource.builtin) {
          throw ArgumentError('Cannot edit system pack');
        }
        final removed = pack.stickers.where((s) => s.id == stickerId).toList();
        if (removed.isEmpty) return;
        final next = pack.stickers.where((s) => s.id != stickerId).toList();
        final removedRefs = removed
            .map((s) => s.localPath)
            .whereType<String>()
            .toSet();
        final updated = pack.copyWith(
          stickers: next,
          coverPath: removedRefs.contains(pack.coverPath)
              ? (next.isEmpty ? null : next.first.localPath)
              : pack.coverPath,
        );
        await _commit({
          pack.id: jsonEncode(updated.toJson()),
          _recentKey: _encodeRecent(
            getRecentStickers().where(
              (s) => s.packId != packId || s.id != stickerId,
            ),
          ),
        });
        await _cleanUnused(removedRefs);
      });

  /// Renames a user pack and returns its new immutable snapshot.
  Future<StickerPack> renamePack(String packId, String name) =>
      _mutate(() async {
        final pack = getPack(packId);
        if (pack == null) throw StateError('Pack not found: $packId');
        if (pack.source == StickerSource.builtin) {
          throw ArgumentError('Cannot edit system pack');
        }
        final trimmed = name.trim();
        if (trimmed.isEmpty) throw ArgumentError('Pack name must not be empty');
        await _savePack(pack.copyWith(name: trimmed));
        return getPack(packId)!;
      });

  /// Moves a sticker to the front of its pack (WeChat "pin to top").
  Future<void> pinSticker(String packId, String stickerId) => _mutate(() async {
    final pack = getPack(packId);
    if (pack == null) return;
    if (pack.source == StickerSource.builtin) {
      throw ArgumentError('Cannot edit system pack');
    }
    final target = pack.stickers.where((s) => s.id == stickerId);
    if (target.isEmpty) return;
    await _savePack(
      pack.copyWith(
        stickers: [
          target.first,
          ...pack.stickers.where((s) => s.id != stickerId),
        ],
      ),
    );
  });

  /// Moves a sticker from [oldIndex] to [newIndex], where [newIndex] is the
  /// final position (as in `onReorderItem`).
  Future<void> reorderStickers(String packId, int oldIndex, int newIndex) =>
      _mutate(() async {
        final pack = getPack(packId);
        if (pack == null) return;
        if (pack.source == StickerSource.builtin) {
          throw ArgumentError('Cannot edit system pack');
        }
        final list = [...pack.stickers];
        if (oldIndex < 0 || oldIndex >= list.length) {
          throw RangeError.index(oldIndex, list, 'oldIndex');
        }
        newIndex = newIndex.clamp(0, list.length - 1);
        list.insert(newIndex, list.removeAt(oldIndex));
        await _savePack(pack.copyWith(stickers: list));
      });

  /// Renames one sticker in a user pack.
  Future<void> renameSticker(String packId, String stickerId, String name) =>
      _mutate(() async {
        final pack = getPack(packId);
        if (pack == null) throw StateError('Pack not found: $packId');
        if (pack.source == StickerSource.builtin) {
          throw ArgumentError('Cannot edit system pack');
        }
        final trimmed = name.trim();
        if (trimmed.isEmpty) throw ArgumentError('Name must not be empty');
        await _savePack(
          pack.copyWith(
            stickers: [
              for (final s in pack.stickers)
                s.id == stickerId ? s.copyWith(name: trimmed) : s,
            ],
          ),
        );
      });

  /// Clears the recently-used history.
  Future<void> clearRecent() =>
      _mutate(() => _commit({_recentKey: _encodeRecent(const [])}));

  /// Creates an empty user pack and returns it.
  Future<StickerPack> createPack(String name) => _mutate(() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Pack name must not be empty');
    final pack = StickerPack(
      id: newId(),
      name: trimmed,
      source: StickerSource.imported,
    );
    await _savePack(pack);
    return getPack(pack.id)!;
  });

  /// Moves a sticker between two user packs, keeping its media.
  Future<void> moveSticker(
    String fromPackId,
    String toPackId,
    String stickerId,
  ) => _mutate(() async {
    if (fromPackId == toPackId) return;
    final from = getPack(fromPackId);
    final to = getPack(toPackId);
    if (from == null || to == null) throw StateError('Pack not found');
    if (from.source == StickerSource.builtin ||
        to.source == StickerSource.builtin) {
      throw ArgumentError('Cannot edit system pack');
    }
    final matches = from.stickers.where((s) => s.id == stickerId).toList();
    if (matches.isEmpty) return;
    if (to.stickers.length >= maxCustomStickers) {
      throw StateError('Target pack is full ($maxCustomStickers)');
    }
    final moved = matches.first.copyWith(packId: to.id);
    final rest = from.stickers.where((s) => s.id != stickerId).toList();
    await _commit({
      from.id: jsonEncode(
        from
            .copyWith(
              stickers: rest,
              coverPath: from.coverPath == moved.localPath
                  ? (rest.isEmpty ? null : rest.first.localPath)
                  : from.coverPath,
            )
            .toJson(),
      ),
      to.id: jsonEncode(
        to
            .copyWith(
              stickers: [...to.stickers, moved],
              coverPath: to.coverPath ?? moved.localPath,
            )
            .toJson(),
      ),
      _recentKey: _encodeRecent(
        getRecentStickers().where(
          (s) => s.packId != fromPackId || s.id != stickerId,
        ),
      ),
    });
  });

  /// Exports favorites as a portable JSON backup (media is base64-encoded).
  /// Stickers without local media are skipped.
  Future<Uint8List> exportFavorites() async {
    await init();
    final items = <Map<String, Object?>>[];
    for (final sticker in customPack.stickers) {
      final bytes = await readStickerBytes(sticker);
      if (bytes == null) continue;
      items.add({
        'name': sticker.name,
        'kind': sticker.kind.name,
        'networkUrl': sticker.networkUrl,
        'data': base64Encode(bytes),
      });
    }
    return Uint8List.fromList(
      utf8.encode(jsonEncode({'version': 1, 'stickers': items})),
    );
  }

  /// Restores a backup made by [exportFavorites]. Duplicates are skipped and
  /// import stops when favorites are full. Returns the number added.
  Future<int> importFavorites(Uint8List data) async {
    await init();
    final decoded = jsonDecode(utf8.decode(data));
    if (decoded is! Map || decoded['stickers'] is! List) {
      throw const FormatException('Not an emoji_weixin backup');
    }
    var added = 0;
    for (final raw in decoded['stickers'] as List) {
      if (isFavoritesFull) break;
      if (raw is! Map || raw['data'] is! String) continue;
      final bytes = base64Decode(raw['data'] as String);
      final ext = sniffImageExtension(bytes);
      if (!isRenderableExtension(ext)) continue;
      final before = customPack.stickers.length;
      await saveCustomBytes(
        name: raw['name'] as String? ?? '',
        kind: isAnimatedImage(bytes)
            ? StickerKind.gif
            : StickerKind.fromName(raw['kind'] as String? ?? ''),
        bytes: bytes,
        extension: ext!,
        networkUrl: raw['networkUrl'] as String?,
      );
      if (customPack.stickers.length > before) added++;
    }
    return added;
  }

  /// Removes several stickers from one pack.
  Future<void> removeStickers(
    String packId,
    Iterable<String> stickerIds,
  ) async {
    for (final id in stickerIds.toSet()) {
      await removeSticker(packId, id);
    }
  }

  /// Generates a UUID for new stickers and files.
  String newId() => _uuid.v4();
}
