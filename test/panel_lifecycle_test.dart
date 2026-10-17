import 'dart:io';

import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:emoji_weixin/src/data/emoji_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('emoji-panel-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temp.path,
        );
  });
  tearDownAll(() async {
    await EmojiStore.instance.db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await temp.delete(recursive: true);
  });

  Widget app(EmojiWeixinConfig config) => MaterialApp(
    home: Scaffold(
      body: EmojiWeixinPanel(config: config, onStickerSelected: (_) {}),
    ),
  );

  testWidgets(
    'config can change during initialization and the panel can close before completion',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(app(const EmojiWeixinConfig()));
        await tester.pumpWidget(
          app(const EmojiWeixinConfig(klipyApiKey: 'test')),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await StickerRepository.instance.init();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'adding and clearing a key updates the search entry without remounting',
    (tester) async {
      await tester.pumpWidget(app(const EmojiWeixinConfig()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.search), findsNothing);
      await tester.pumpWidget(
        app(const EmojiWeixinConfig(klipyApiKey: 'test')),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
      await tester.pumpWidget(app(const EmojiWeixinConfig()));
      expect(find.byIcon(Icons.search), findsNothing);
    },
  );
  testWidgets(
    'sending still invokes the host when history storage is unavailable',
    (tester) async {
      Sticker? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiWeixinPanel(
              onStickerSelected: (sticker) => selected = sticker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => EmojiStore.instance.db.close());
      await tester.tap(find.byType(StickerRenderer).first);
      expect(selected, isNotNull);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
