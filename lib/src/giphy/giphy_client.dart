import 'dart:convert';

import 'package:http/http.dart' as http;

class GiphyGifItem {
  const GiphyGifItem({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
    required this.isSticker,
  });

  final String id;
  final String title;
  final String previewUrl;
  final String originalUrl;
  final bool isSticker;
}

class GiphyClient {
  GiphyClient({
    required this.apiKey,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _http;

  static const _base = 'https://api.giphy.com/v1';

  Future<List<GiphyGifItem>> searchStickers({
    required String query,
    int limit = 24,
    int offset = 0,
  }) {
    return _search(
      path: 'stickers/search',
      query: query,
      limit: limit,
      offset: offset,
      isSticker: true,
    );
  }

  Future<List<GiphyGifItem>> searchGifs({
    required String query,
    int limit = 24,
    int offset = 0,
  }) {
    return _search(
      path: 'gifs/search',
      query: query,
      limit: limit,
      offset: offset,
      isSticker: false,
    );
  }

  Future<List<GiphyGifItem>> trendingStickers({
    int limit = 24,
    int offset = 0,
  }) {
    return _trending(
      path: 'stickers/trending',
      limit: limit,
      offset: offset,
      isSticker: true,
    );
  }

  Future<List<GiphyGifItem>> _search({
    required String path,
    required String query,
    required int limit,
    required int offset,
    required bool isSticker,
  }) async {
    final uri = Uri.parse('$_base/$path').replace(queryParameters: {
      'api_key': apiKey,
      'q': query,
      'limit': '$limit',
      'offset': '$offset',
      'rating': 'pg',
      'lang': 'zh-CN',
    });
    return _fetch(uri, isSticker: isSticker);
  }

  Future<List<GiphyGifItem>> _trending({
    required String path,
    required int limit,
    required int offset,
    required bool isSticker,
  }) async {
    final uri = Uri.parse('$_base/$path').replace(queryParameters: {
      'api_key': apiKey,
      'limit': '$limit',
      'offset': '$offset',
      'rating': 'pg',
    });
    return _fetch(uri, isSticker: isSticker);
  }

  Future<List<GiphyGifItem>> _fetch(
    Uri uri, {
    required bool isSticker,
  }) async {
    final res = await _http.get(uri);
    if (res.statusCode != 200) {
      throw StateError('Giphy error ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? const [];
    return data.map((raw) {
      final map = raw as Map<String, dynamic>;
      final images = map['images'] as Map<String, dynamic>? ?? const {};
      final preview = (images['fixed_width'] ?? images['preview_gif'] ?? images['original'])
          as Map<String, dynamic>?;
      final original = images['original'] as Map<String, dynamic>?;
      return GiphyGifItem(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        previewUrl: preview?['url'] as String? ?? '',
        originalUrl: original?['url'] as String? ?? preview?['url'] as String? ?? '',
        isSticker: isSticker,
      );
    }).where((e) => e.previewUrl.isNotEmpty).toList();
  }

  void close() => _http.close();
}
