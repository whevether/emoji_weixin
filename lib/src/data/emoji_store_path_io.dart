import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Documents directory used as the ToStore [dbPath] on IO platforms.
Future<String?> emojiStorePath() async {
  final docs = await getApplicationDocumentsDirectory();
  return p.join(docs.path, 'emoji_weixin', 'tostore');
}
