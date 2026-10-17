import 'package:http/http.dart' as http;

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../network/bounded_download.dart';
import 'klipy_client.dart';

/// Downloads Klipy / network stickers into the favorites pack.
class KlipyStickerService {
  /// Creates a service; [client] is optional for search-related callers.
  KlipyStickerService({
    @Deprecated('Search with KlipyClient directly') this.client,
    StickerRepository? repository,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
    this.maxDownloadBytes = 20 * 1024 * 1024,
  }) : _repo = repository ?? StickerRepository.instance,
       _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  /// Optional; only needed when calling search APIs via [client].
  @Deprecated('Search with KlipyClient directly')
  final KlipyClient? client;
  final StickerRepository _repo;
  final http.Client _http;
  final bool _ownsClient;

  /// Deadline for one complete media download.
  final Duration timeout;

  /// Maximum size of a downloaded sticker.
  final int maxDownloadBytes;

  /// Releases the client created by this service; injected clients stay open.
  void close() {
    if (_ownsClient) _http.close();
  }

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
    final response = await boundedDownload(
      _http,
      Uri.parse(url),
      timeout: timeout,
      maxBytes: maxDownloadBytes,
    );
    final ext = stickerExtension(response.bytes, response.contentType);
    return _repo.saveCustomBytes(
      name: name,
      kind: StickerKind.fromExtension(ext),
      bytes: response.bytes,
      extension: ext,
      networkUrl: url,
    );
  }
}
