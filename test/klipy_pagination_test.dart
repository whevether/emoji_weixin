import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:emoji_weixin/src/ui/klipy_search_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

KlipyGifItem item(String id) => KlipyGifItem(
  id: id,
  title: id,
  previewUrl: 'https://example.invalid/$id.gif',
  originalUrl: 'https://example.invalid/$id.gif',
  isSticker: true,
);

class PagedClient extends KlipyClient {
  PagedClient({this.fail = false}) : super(apiKey: 'unused');
  final bool fail;
  final pages = <int>[];

  @override
  Future<List<KlipyGifItem>> trendingStickers({
    int page = 1,
    int perPage = 24,
  }) async {
    pages.add(page);
    if (fail) throw Exception('secret-internal-detail');
    if (page > 2) return const [];
    return List.generate(30, (i) => item('p$page-$i'));
  }
}

Widget app(KlipyClient client) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      height: 320,
      child: KlipySearchTab(
        client: client,
        strings: EmojiWeixinStrings.of(EmojiWeixinLocale.en),
        onSelected: (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('scrolling to the end loads the next page once', (tester) async {
    final client = PagedClient();
    addTearDown(client.close);
    await tester.pumpWidget(app(client));
    await tester.pump();
    expect(client.pages, [1]);
    await tester.drag(find.byType(GridView), const Offset(0, -2000));
    await tester.pump();
    await tester.pump();
    expect(client.pages, contains(2));
    expect(client.pages.where((p) => p == 2), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('errors show friendly text with retry, not raw exceptions', (
    tester,
  ) async {
    final client = PagedClient(fail: true);
    addTearDown(client.close);
    await tester.pumpWidget(app(client));
    await tester.pump();
    expect(find.textContaining('secret-internal-detail'), findsNothing);
    expect(
      find.text(
        EmojiWeixinStrings.of(EmojiWeixinLocale.en).searchFailedMessage,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(client.pages.length, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
