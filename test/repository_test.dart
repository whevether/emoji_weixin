import 'dart:async';
import 'dart:io';

import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:emoji_weixin/src/platform/sticker_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tostore/tostore.dart';

class ControlledStore implements ToStore {
  ControlledStore(this.inner);
  final ToStore inner;
  bool rejectWrites = false;
  String? rejectKey;

  @override
  get kv => inner.kv;

  @override
  Future<DbResult> setValue(
    String key,
    dynamic value, {
    Duration? ttl,
    DateTime? expiresAt,
    bool isGlobal = false,
    RecoveryDurability? durability,
  }) async {
    if (rejectWrites || rejectKey == key) {
      return DbResult.error(
        type: ResultType.engError,
        message: 'Injected storage failure',
      );
    }
    return inner.setValue(
      key,
      value,
      ttl: ttl,
      expiresAt: expiresAt,
      isGlobal: isGlobal,
      durability: durability,
    );
  }

  @override
  Future<DbResult> removeValue(String key, {bool isGlobal = false}) =>
      inner.removeValue(key, isGlobal: isGlobal);

  @override
  Future<TransactionResult> transaction<T>(
    FutureOr<T> Function() action, {
    bool rollbackOnError = true,
    bool? persistRecoveryOnCommit,
    TransactionIsolationLevel? isolation,
  }) => inner.transaction(
    action,
    rollbackOnError: rollbackOnError,
    persistRecoveryOnCommit: persistRecoveryOnCommit,
    isolation: isolation,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late ToStore db;
  late ControlledStore store;
  late StickerRepository repo;
  var sequence = 0;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('emoji-repository-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
  });
  setUp(() async {
    db = await ToStore.open(dbPath: temp.path, dbName: 'test_${sequence++}');
    store = ControlledStore(db);
    repo = StickerRepository.forTesting(
      database: store,
      loadBuiltinPack: () async => null,
    );
  });
  tearDown(() async {
    await db.close();
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await temp.delete(recursive: true);
  });

  test('concurrent initialization awaits the entire asset load and shares one future', () async {
    final loading = Completer<void>();
    final assets = Completer<StickerPack?>();
    var calls = 0;
    repo = StickerRepository.forTesting(
      database: store,
      loadBuiltinPack: () {
        calls++;
        loading.complete();
        return assets.future;
      },
    );
    final first = repo.init();
    final second = repo.init();
    expect(identical(first, second), isTrue);
    await loading.future;
    var completed = false;
    second.then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    assets.complete(null);
    await Future.wait([first, second]);
    expect(calls, 1);
    expect(repo.customPack.id, 'custom');
  });

  test('initialization retries after a non-throwing database error', () async {
    store.rejectWrites = true;
    await expectLater(repo.init(), throwsStateError);
    store.rejectWrites = false;
    await repo.init();
    expect(repo.customPack.stickers, isEmpty);
  });

  test('concurrent favorites and recent updates keep every item', () async {
    final stickers = await Future.wait(
      List.generate(
        12,
        (i) => repo.addStickerToCustom(
          name: '$i',
          kind: StickerKind.gif,
          localPath: '/external/$i.gif',
        ),
      ),
    );
    expect(repo.customPack.stickers, hasLength(12));
    await Future.wait(stickers.map(repo.recordRecent));
    expect(repo.getRecentStickers(), hasLength(12));
    expect(repo.getRecentStickers().first.id, stickers.last.id);
  });

  test('failed writes leave cached snapshots unchanged and do not poison the queue', () async {
    await repo.init();
    final before = repo.customPack;
    store.rejectWrites = true;
    await expectLater(
      repo.addStickerToCustom(
        name: 'lost',
        kind: StickerKind.gif,
        localPath: '/external/a.gif',
      ),
      throwsStateError,
    );
    expect(identical(repo.customPack, before), isTrue);
    store.rejectWrites = false;
    await repo.addStickerToCustom(
      name: 'saved',
      kind: StickerKind.gif,
      localPath: '/external/b.gif',
    );
    expect(repo.customPack.stickers.single.name, 'saved');
  });

  test(
    'failed favorite metadata is rolled back by removing the new media',
    () async {
      await repo.init();
      final files = Directory('${temp.path}/emoji_weixin/packs/custom/files');
      final before = await files.exists() ? await files.list().length : 0;
      store.rejectWrites = true;
      await expectLater(
        repo.saveCustomBytes(
          name: 'lost',
          kind: StickerKind.gif,
          bytes: Uint8List.fromList([1, 2, 3]),
          extension: 'gif',
        ),
        throwsStateError,
      );
      expect(await files.list().length, before);
    },
  );

  test('deleting a sticker clears recent and cover but keeps media used by another pack', () async {
    final sticker = await repo.saveCustomBytes(
      name: 'shared',
      kind: StickerKind.gif,
      bytes: Uint8List.fromList([1, 2, 3]),
      extension: 'gif',
    );
    await repo.recordRecent(sticker);
    await repo.savePack(
      StickerPack(
        id: 'imported',
        name: 'other',
        source: StickerSource.imported,
        stickers: [sticker.copyWith(id: 'other', packId: 'imported')],
      ),
    );
    await repo.removeSticker('custom', sticker.id);
    expect(repo.getRecentStickers(), isEmpty);
    expect(repo.customPack.coverPath, isNull);
    expect(await File(sticker.localPath!).exists(), isTrue);
    await repo.deletePack('imported');
    expect(await File(sticker.localPath!).exists(), isFalse);
  });

  test('pinSticker moves a favorite to the front', () async {
    final a = await repo.addStickerToCustom(
      name: 'a',
      kind: StickerKind.gif,
      localPath: '/external/a.gif',
    );
    await repo.addStickerToCustom(
      name: 'b',
      kind: StickerKind.gif,
      localPath: '/external/b.gif',
    );
    final c = await repo.addStickerToCustom(
      name: 'c',
      kind: StickerKind.gif,
      localPath: '/external/c.gif',
    );
    await repo.pinSticker('custom', c.id);
    expect(repo.customPack.stickers.map((s) => s.name), ['c', 'a', 'b']);
    expect(repo.customPack.stickers.map((s) => s.id), contains(a.id));
  });

  test('reorderStickers moves a favorite to its final index', () async {
    final a = await repo.addStickerToCustom(
      name: 'a',
      kind: StickerKind.gif,
      localPath: '/external/a.gif',
    );
    await repo.addStickerToCustom(
      name: 'b',
      kind: StickerKind.gif,
      localPath: '/external/b.gif',
    );
    await repo.addStickerToCustom(
      name: 'c',
      kind: StickerKind.gif,
      localPath: '/external/c.gif',
    );
    await repo.reorderStickers('custom', 0, 2);
    expect(repo.customPack.stickers.map((s) => s.name), ['b', 'c', 'a']);
    await repo.reorderStickers('custom', 2, 0);
    expect(repo.customPack.stickers.first.id, a.id);
  });

  test('identical media content is stored only once', () async {
    final first = await repo.saveCustomBytes(
      name: 'a',
      kind: StickerKind.gif,
      bytes: Uint8List.fromList([1, 2, 3]),
      extension: 'gif',
    );
    final second = await repo.saveCustomBytes(
      name: 'b',
      kind: StickerKind.gif,
      bytes: Uint8List.fromList([1, 2, 3]),
      extension: 'png',
    );
    expect(second.id, first.id);
    expect(first.contentHash, isNotNull);
    expect(repo.customPack.stickers, hasLength(1));
    await repo.saveCustomBytes(
      name: 'c',
      kind: StickerKind.gif,
      bytes: Uint8List.fromList([4, 5, 6]),
      extension: 'gif',
    );
    expect(repo.customPack.stickers, hasLength(2));
  });

  test(
    'readStickerBytes returns stored media; network-only gives null',
    () async {
      final saved = await repo.saveCustomBytes(
        name: 'a',
        kind: StickerKind.gif,
        bytes: Uint8List.fromList([9, 8, 7]),
        extension: 'gif',
      );
      expect(await repo.readStickerBytes(saved), [9, 8, 7]);
      expect(repo.isFavoritesFull, isFalse);
      const remote = Sticker(
        id: 'r',
        packId: 'klipy',
        name: 'r',
        kind: StickerKind.gif,
        networkUrl: 'https://example.com/a.gif',
      );
      expect(await repo.readStickerBytes(remote), isNull);
    },
  );

  test('rename, move, clear recent and backup round trip', () async {
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, 4, //
    ]);
    final saved = await repo.saveCustomBytes(
      name: 'a',
      kind: StickerKind.staticImage,
      bytes: png,
      extension: 'png',
    );
    await repo.renameSticker('custom', saved.id, ' b ');
    expect(repo.customPack.stickers.single.name, 'b');

    final pack = await repo.createPack('Mine');
    await repo.moveSticker('custom', pack.id, saved.id);
    expect(repo.customPack.stickers, isEmpty);
    expect(repo.getPack(pack.id)!.stickers.single.packId, pack.id);
    await repo.moveSticker(pack.id, 'custom', saved.id);

    final backup = await repo.exportFavorites();
    await repo.removeSticker('custom', saved.id);
    expect(await repo.importFavorites(backup), 1);
    expect(repo.customPack.stickers.single.name, 'b');
    expect(await repo.importFavorites(backup), 0);

    await repo.recordRecent(repo.customPack.stickers.single);
    await repo.clearRecent();
    expect(repo.getRecentStickers(), isEmpty);
  });

  test('removeStickers deletes several favorites at once', () async {
    final a = await repo.addStickerToCustom(
      name: 'a',
      kind: StickerKind.gif,
      localPath: '/external/a.gif',
    );
    final b = await repo.addStickerToCustom(
      name: 'b',
      kind: StickerKind.gif,
      localPath: '/external/b.gif',
    );
    await repo.addStickerToCustom(
      name: 'c',
      kind: StickerKind.gif,
      localPath: '/external/c.gif',
    );
    await repo.removeStickers('custom', [a.id, b.id]);
    expect(repo.customPack.stickers.map((s) => s.name), ['c']);
  });

  test('favorites are capped at maxCustomStickers', () async {
    await repo.init();
    await repo.savePack(
      repo.customPack.copyWith(
        stickers: List.generate(
          StickerRepository.maxCustomStickers,
          (i) => Sticker(
            id: 's$i',
            packId: 'custom',
            name: '$i',
            kind: StickerKind.gif,
            localPath: '/external/$i.gif',
          ),
        ),
      ),
    );
    await expectLater(
      repo.addStickerToCustom(
        name: 'x',
        kind: StickerKind.gif,
        localPath: '/external/x.gif',
      ),
      throwsStateError,
    );
  });

  test('multi-record failure rolls back metadata as well as cache', () async {
    final sticker = await repo.addStickerToCustom(
      name: 'keep',
      kind: StickerKind.gif,
      localPath: '/external/a.gif',
    );
    await repo.recordRecent(sticker);
    store.rejectKey = '_recent_stickers';
    await expectLater(
      repo.removeSticker('custom', sticker.id),
      throwsStateError,
    );
    expect(repo.customPack.stickers.single.id, sticker.id);
    expect(repo.getRecentStickers().single.id, sticker.id);
    expect((await db.getValue('custom')).toString(), contains(sticker.id));
  });

  test(
    'deleting a pack preserves media still referenced by chat history',
    () async {
      await repo.init();
      final ref = await StickerStorage.saveBytes(
        packId: 'history_pack',
        filename: 'shared.gif',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      final sticker = Sticker(
        id: 'shared',
        packId: 'history_pack',
        name: 'shared',
        kind: StickerKind.gif,
        localPath: ref,
      );
      await repo.savePack(
        StickerPack(
          id: 'history_pack',
          name: 'history',
          source: StickerSource.imported,
          stickers: [sticker],
        ),
      );
      await repo.recordRecent(sticker.copyWith(packId: 'chat'));
      await repo.deletePack('history_pack');
      expect(await File(ref).exists(), isTrue);
      expect(repo.getRecentStickers().single.packId, 'chat');
    },
  );

  test(
    'storage rejects traversal and symlink escapes before deleting anything',
    () async {
      await repo.init();
      final outside = File('${temp.path}/keep.gif');
      await outside.writeAsString('keep');
      await expectLater(
        StickerStorage.deletePackDir('../'),
        throwsArgumentError,
      );
      await expectLater(
        StickerStorage.saveBytes(
          packId: 'custom',
          filename: '../../keep.gif',
          bytes: Uint8List(1),
        ),
        throwsArgumentError,
      );
      await expectLater(
        StickerStorage.deleteBytes(outside.path),
        throwsArgumentError,
      );
      final link = Link('${temp.path}/emoji_weixin/packs/escape');
      await link.create(temp.path);
      await expectLater(
        StickerStorage.saveBytes(
          packId: 'escape',
          filename: 'keep.gif',
          bytes: Uint8List(1),
        ),
        throwsArgumentError,
      );
      expect(await outside.readAsString(), 'keep');
      await link.delete();
    },
  );
}
