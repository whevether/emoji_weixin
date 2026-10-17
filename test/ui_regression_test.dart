import 'dart:async';

import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:emoji_weixin/src/ui/klipy_search_tab.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class PendingSearch extends KlipyClient {
  PendingSearch() : super(apiKey: 'unused');
  final trending = Completer<List<KlipyGifItem>>();
  final queries = <String, Completer<List<KlipyGifItem>>>{};

  @override
  Future<List<KlipyGifItem>> trendingStickers({
    int page = 1,
    int perPage = 24,
  }) => trending.future;

  @override
  Future<List<KlipyGifItem>> searchStickers({
    required String query,
    int page = 1,
    int perPage = 24,
  }) => (queries[query] ??= Completer<List<KlipyGifItem>>()).future;
}

KlipyGifItem result(String name) => KlipyGifItem(
  id: name,
  title: name,
  previewUrl: 'https://example.invalid/$name.gif',
  originalUrl: 'https://example.invalid/$name.gif',
  isSticker: true,
);

Widget searchApp(PendingSearch client) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      height: 320,
      child: KlipySearchTab(
        client: client,
        strings: EmojiWeixinStrings.of(EmojiWeixinLocale.zh),
        onSelected: (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'late search and trending responses cannot replace the latest query',
    (tester) async {
      final client = PendingSearch();
      addTearDown(client.close);
      await tester.pumpWidget(searchApp(client));
      await tester.enterText(find.byType(TextField), 'old');
      await tester.pump(const Duration(milliseconds: 401));
      await tester.enterText(find.byType(TextField), 'new');
      await tester.pump(const Duration(milliseconds: 401));
      client.queries['new']!.complete([result('new')]);
      await tester.pump();
      client.queries['old']!.complete([result('old')]);
      client.trending.complete([result('trending')]);
      await tester.pump();
      final image = tester.widget<ExtendedImage>(find.byType(ExtendedImage));
      expect(
        (image.image as ExtendedNetworkImageProvider).url,
        endsWith('/new.gif'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('search completion after disposal does not update state', (
    tester,
  ) async {
    final client = PendingSearch();
    addTearDown(client.close);
    await tester.pumpWidget(searchApp(client));
    await tester.pumpWidget(const SizedBox.shrink());
    client.trending.complete([result('late')]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'replacing the client invalidates responses from the previous configuration',
    (tester) async {
      final old = PendingSearch();
      final next = PendingSearch();
      addTearDown(old.close);
      addTearDown(next.close);
      await tester.pumpWidget(searchApp(old));
      await tester.pumpWidget(searchApp(next));
      next.trending.complete([result('next')]);
      await tester.pump();
      old.trending.complete([result('old')]);
      await tester.pump();
      final image = tester.widget<ExtendedImage>(find.byType(ExtendedImage));
      expect(
        (image.image as ExtendedNetworkImageProvider).url,
        endsWith('/next.gif'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
