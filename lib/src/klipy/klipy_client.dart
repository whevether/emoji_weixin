import 'dart:convert';

import 'package:http/http.dart' as http;

class KlipyGifItem {
  const KlipyGifItem({
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

/// Thin client for [KLIPY native API](https://docs.klipy.com/).
class KlipyClient {
  KlipyClient({
    required this.apiKey,
    this.locale = 'cn',
    this.contentFilter = 'medium',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String locale;
  final String contentFilter;
  final http.Client _http;

  static const _base = 'https://api.klipy.com/api/v1';

  Future<List<KlipyGifItem>> searchStickers({
    required String query,
    int page = 1,
    int perPage = 24,
  }) {
    return _fetch(
      path: 'stickers/search',
      query: {
        'q': query,
        'page': '$page',
        'per_page': '${_clampPerPage(perPage)}',
        'locale': locale,
        'content_filter': contentFilter,
        'format_filter': 'gif,webp',
      },
      isSticker: true,
    );
  }

  Future<List<KlipyGifItem>> searchGifs({
    required String query,
    int page = 1,
    int perPage = 24,
  }) {
    return _fetch(
      path: 'gifs/search',
      query: {
        'q': query,
        'page': '$page',
        'per_page': '${_clampPerPage(perPage)}',
        'locale': locale,
        'content_filter': contentFilter,
        'format_filter': 'gif,webp',
      },
      isSticker: false,
    );
  }

  Future<List<KlipyGifItem>> trendingStickers({
    int page = 1,
    int perPage = 24,
  }) {
    return _fetch(
      path: 'stickers/trending',
      query: {
        'page': '$page',
        'per_page': '${_clampPerPage(perPage)}',
        'locale': locale,
        'content_filter': contentFilter,
        'format_filter': 'gif,webp',
      },
      isSticker: true,
    );
  }

  Future<List<KlipyGifItem>> trendingGifs({
    int page = 1,
    int perPage = 24,
  }) {
    return _fetch(
      path: 'gifs/trending',
      query: {
        'page': '$page',
        'per_page': '${_clampPerPage(perPage)}',
        'locale': locale,
        'content_filter': contentFilter,
        'format_filter': 'gif,webp',
      },
      isSticker: false,
    );
  }

  Future<List<KlipyGifItem>> _fetch({
    required String path,
    required Map<String, String> query,
    required bool isSticker,
  }) async {
    final uri = Uri.parse('$_base/$apiKey/$path').replace(
      queryParameters: query,
    );
    final res = await _http.get(uri);
    if (res.statusCode != 200) {
      throw StateError('Klipy error ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'];
    final List<dynamic> items;
    if (data is Map<String, dynamic>) {
      items = data['data'] as List<dynamic>? ?? const [];
    } else if (data is List<dynamic>) {
      items = data;
    } else {
      items = const [];
    }

    return items
        .map((raw) => _parseItem(raw as Map<String, dynamic>, isSticker: isSticker))
        .whereType<KlipyGifItem>()
        .where((e) => e.previewUrl.isNotEmpty && e.originalUrl.isNotEmpty)
        .toList();
  }

  KlipyGifItem? _parseItem(
    Map<String, dynamic> map, {
    required bool isSticker,
  }) {
    final file = map['file'] as Map<String, dynamic>? ?? const {};
    final preview = _pickUrl(
          file,
          formats: const ['gif', 'webp', 'jpg'],
          tiers: const ['sm', 'md', 'xs', 'hd'],
        ) ??
        '';
    final original = _pickUrl(
          file,
          formats: const ['gif', 'webp'],
          tiers: const ['md', 'hd', 'sm'],
        ) ??
        preview;
    if (preview.isEmpty && original.isEmpty) return null;

    final idValue = map['id'];
    return KlipyGifItem(
      id: idValue?.toString() ?? map['slug']?.toString() ?? '',
      title: map['title'] as String? ?? map['slug'] as String? ?? '',
      previewUrl: preview.isNotEmpty ? preview : original,
      originalUrl: original.isNotEmpty ? original : preview,
      isSticker: isSticker,
    );
  }

  /// Prefer first available `file[tier][format].url`.
  static String? _pickUrl(
    Map<String, dynamic> file, {
    required List<String> formats,
    required List<String> tiers,
  }) {
    for (final tier in tiers) {
      final tierMap = file[tier];
      if (tierMap is! Map<String, dynamic>) continue;
      for (final format in formats) {
        final fmt = tierMap[format];
        if (fmt is! Map<String, dynamic>) continue;
        final url = fmt['url'] as String? ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  static int _clampPerPage(int perPage) {
    if (perPage < 8) return 8;
    if (perPage > 50) return 50;
    return perPage;
  }

  void close() => _http.close();
}
