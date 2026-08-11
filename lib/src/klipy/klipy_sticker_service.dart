import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../platform/sticker_storage.dart';
import 'klipy_client.dart';

class KlipyStickerService {
  KlipyStickerService({
    this.client,
    StickerRepository? repository,
    http.Client? httpClient,
  })  : _repo = repository ?? StickerRepository.instance,
        _http = httpClient ?? http.Client();

  /// Optional; only needed when calling search APIs via [client].
  final KlipyClient? client;
  final StickerRepository _repo;
  final http.Client _http;

  /// Download a Klipy search result into the custom favorites pack.
  Future<Sticker> composeToFavorite(KlipyGifItem item) {
    return saveUrlToFavorite(
      url: item.originalUrl,
      name: item.title.isEmpty ? 'Klipy' : item.title,
    );
  }

  /// Download a chat sticker (network) into favorites.
  Future<Sticker> saveStickerToFavorite(Sticker sticker) async {
    final url = sticker.networkUrl;
    if (url == null || url.isEmpty) {
      throw StateError('Sticker has no networkUrl to favorite');
    }
    return saveUrlToFavorite(
      url: url,
      name: sticker.name.isEmpty ? 'Klipy' : sticker.name,
    );
  }

  /// Download [url] and save into the custom favorites pack.
  Future<Sticker> saveUrlToFavorite({
    required String url,
    String name = 'Klipy',
  }) async {
    await _repo.init();
    final res = await _http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw StateError('Failed to download media: ${res.statusCode}');
    }

    final uriPath = Uri.parse(url).path;
    var ext = p.extension(uriPath).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty || ext.length > 4) ext = 'gif';

    final id = _repo.newId();
    final ref = await StickerStorage.saveBytes(
      packId: 'custom',
      filename: '$id.$ext',
      bytes: res.bodyBytes,
    );

    return _repo.addStickerToCustom(
      name: name,
      kind: StickerKind.fromExtension(ext),
      localPath: ref,
      networkUrl: url,
    );
  }
}
