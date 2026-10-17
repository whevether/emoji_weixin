import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/bounded_download.dart';

/// A single Klipy search / trending result.
class KlipyGifItem {
  /// Creates a Klipy media item.
  const KlipyGifItem({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.originalUrl,
    required this.isSticker,
  });

  /// Provider id (or slug fallback).
  final String id;

  /// Display title from Klipy.
  final String title;

  /// Smaller preview URL for grid thumbnails.
  final String previewUrl;

  /// Full-size download URL.
  final String originalUrl;

  /// `true` for sticker endpoints; `false` for GIF endpoints.
  final bool isSticker;
}

/// Thin client for [KLIPY native API](https://docs.klipy.com/).
class KlipyClient {
  /// Creates a client with the given [apiKey].
  KlipyClient({
    required this.apiKey,
    this.locale = 'cn',
    this.contentFilter = 'medium',
    http.Client? httpClient,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 2 * 1024 * 1024,
  }) : _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _baseUri = baseUri ?? Uri.parse('https://api.klipy.com/api/v1/');

  /// Klipy API key embedded in request paths.
  final String apiKey;

  /// Klipy locale query param (e.g. `cn`, `en`).
  final String locale;

  /// Klipy content filter level (e.g. `medium`).
  final String contentFilter;
  final http.Client _http;

  final bool _ownsClient;
  final Uri _baseUri;

  /// Maximum duration for a search response.
  final Duration timeout;

  /// Maximum JSON response size.
  final int maxResponseBytes;

  /// Searches stickers for a query.
  Future<List<KlipyGifItem>> searchStickers({
    required String query,
    int page = 1,
    int perPage = 24,
  }) => _query(isSticker: true, query: query, page: page, perPage: perPage);

  /// Searches GIFs for a query.
  Future<List<KlipyGifItem>> searchGifs({
    required String query,
    int page = 1,
    int perPage = 24,
  }) => _query(isSticker: false, query: query, page: page, perPage: perPage);

  /// Returns trending stickers.
  Future<List<KlipyGifItem>> trendingStickers({
    int page = 1,
    int perPage = 24,
  }) => _query(isSticker: true, page: page, perPage: perPage);

  /// Returns trending GIFs.
  Future<List<KlipyGifItem>> trendingGifs({int page = 1, int perPage = 24}) =>
      _query(isSticker: false, page: page, perPage: perPage);

  Future<List<KlipyGifItem>> _query({
    required bool isSticker,
    String? query,
    required int page,
    required int perPage,
  }) {
    if (page < 1) throw ArgumentError.value(page, 'page');
    return _fetch(
      path:
          '${isSticker ? 'stickers' : 'gifs'}/${query == null ? 'trending' : 'search'}',
      query: {
        if (query != null) 'q': query.trim(),
        'page': '$page',
        'per_page': '${_clampPerPage(perPage)}',
        'locale': locale,
        'content_filter': contentFilter,
        'format_filter': 'gif,webp',
      },
      isSticker: isSticker,
    );
  }

  Future<List<KlipyGifItem>> _fetch({
    required String path,
    required Map<String, String> query,
    required bool isSticker,
  }) async {
    final base = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('$_baseUri/');
    final uri = base
        .resolve('${Uri.encodeComponent(apiKey)}/$path')
        .replace(queryParameters: query);
    final res = await boundedDownload(
      _http,
      uri,
      timeout: timeout,
      maxBytes: maxResponseBytes,
    );
    final decoded = jsonDecode(utf8.decode(res.bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Klipy response');
    }
    final json = decoded;
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
        .whereType<Map<String, dynamic>>()
        .map((raw) => _parseItem(raw, isSticker: isSticker))
        .whereType<KlipyGifItem>()
        .where((e) => e.previewUrl.isNotEmpty && e.originalUrl.isNotEmpty)
        .toList();
  }

  KlipyGifItem? _parseItem(
    Map<String, dynamic> map, {
    required bool isSticker,
  }) {
    final rawFile = map['file'];
    if (rawFile is! Map<String, dynamic>) return null;
    final file = rawFile;
    final preview =
        _pickUrl(
          file,
          formats: const ['gif', 'webp', 'jpg'],
          tiers: const ['sm', 'md', 'xs', 'hd'],
        ) ??
        '';
    final original =
        _pickUrl(
          file,
          formats: const ['gif', 'webp'],
          tiers: const ['md', 'hd', 'sm'],
        ) ??
        preview;
    if (preview.isEmpty && original.isEmpty) return null;

    final idValue = map['id'];
    return KlipyGifItem(
      id: idValue?.toString() ?? map['slug']?.toString() ?? '',
      title: map['title']?.toString() ?? map['slug']?.toString() ?? '',
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
        final url = fmt['url'];
        if (url is String && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null &&
              {'http', 'https'}.contains(uri.scheme) &&
              uri.host.isNotEmpty) {
            return url;
          }
        }
      }
    }
    return null;
  }

  static int _clampPerPage(int perPage) {
    if (perPage < 8) return 8;
    if (perPage > 50) return 50;
    return perPage;
  }

  /// Closes the owned HTTP client; injected clients remain open.
  void close() {
    if (_ownsClient) _http.close();
  }
}
