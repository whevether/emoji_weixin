import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Demo app smoke test', (tester) async {
    await tester.pumpWidget(const EmojiWeixinDemoApp());
    expect(find.text('表情包演示'), findsOneWidget);
  });
}
