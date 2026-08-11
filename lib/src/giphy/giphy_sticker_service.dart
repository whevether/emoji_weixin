import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../platform/sticker_storage.dart';
import 'giphy_client.dart';

class GiphyStickerService {
  GiphyStickerService({
    required this.client,
    StickerRepository? repository,
    http.Client? httpClient,
  })  : _repo = repository ?? StickerRepository.instance,
        _http = httpClient ?? http.Client();

  final GiphyClient client;
  final StickerRepository _repo;
  final http.Client _http;

  /// Download a Giphy result and save it into the custom favorites pack.
  Future<Sticker> composeToFavorite(GiphyGifItem item) async {
    final res = await _http.get(Uri.parse(item.originalUrl));
    if (res.statusCode != 200) {
      throw StateError('Failed to download Giphy media: ${res.statusCode}');
    }

    final uriPath = Uri.parse(item.originalUrl).path;
    var ext = p.extension(uriPath).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty || ext.length > 4) ext = 'gif';

    final id = _repo.newId();
    final ref = await StickerStorage.saveBytes(
      packId: 'custom',
      filename: '$id.$ext',
      bytes: res.bodyBytes,
    );

    return _repo.addStickerToCustom(
      name: item.title.isEmpty ? 'Giphy' : item.title,
      kind: StickerKind.fromExtension(ext),
      localPath: ref,
      networkUrl: item.originalUrl,
    );
  }
}
