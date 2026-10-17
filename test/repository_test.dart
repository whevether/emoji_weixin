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
