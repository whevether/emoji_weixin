import 'dart:async';

import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:emoji_weixin/src/network/bounded_download.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const base = String.fromEnvironment('SIMULATION_URL');
  final skip = base.isEmpty
      ? 'Run against the local Postman simulation'
      : false;
  late KlipyClient client;
  late http.Client transport;
  setUp(() {
    transport = http.Client();
    client = KlipyClient(
      apiKey: 'test-key',
      baseUri: Uri.parse('$base/api/v1/'),
      httpClient: transport,
    );
  });
  tearDown(() {
    client.close();
    transport.close();
  });

  test(
    'real HTTP search parses the provider response and skips malformed entries',
    () async {
      final items = await client.searchStickers(query: 'cats');
      expect(items.single.title, 'cats');
      expect(items.single.originalUrl, endsWith('original.gif'));
    },
    skip: skip,
  );

  test(
    'non-200 and malformed JSON fail without exposing the response body',
    () async {
      await expectLater(
        client.searchGifs(query: 'http-error'),
        throwsStateError,
      );
      await expectLater(
        client.searchStickers(query: 'invalid-json'),
        throwsFormatException,
      );
    },
    skip: skip,
  );

  test('timeout aborts an actual pending HTTP request', () async {
    final short = KlipyClient(
      apiKey: 'test-key',
      baseUri: Uri.parse('$base/api/v1/'),
      timeout: const Duration(milliseconds: 80),
    );
    addTearDown(short.close);
    await expectLater(
      short.searchStickers(query: 'slow'),
      throwsA(isA<TimeoutException>()),
    );
  }, skip: skip);

  test('GIF bytes are detected and HTML is rejected', () async {
    final gif = await boundedDownload(
      transport,
      Uri.parse('$base/media/gif'),
      timeout: const Duration(seconds: 2),
      maxBytes: 100,
    );
    expect(stickerExtension(gif.bytes, gif.contentType), 'gif');
    final html = await boundedDownload(
      transport,
      Uri.parse('$base/media/html'),
      timeout: const Duration(seconds: 2),
      maxBytes: 100,
    );
    expect(
      () => stickerExtension(html.bytes, html.contentType),
      throwsFormatException,
    );
  }, skip: skip);

  test('both declared and streamed response sizes are bounded', () async {
    for (final path in ['large', 'chunked']) {
      await expectLater(
        boundedDownload(
          transport,
          Uri.parse('$base/media/$path'),
          timeout: const Duration(seconds: 2),
          maxBytes: 150,
        ),
        throwsStateError,
      );
    }
  }, skip: skip);

  test('deadline covers response bodies, not just headers', () async {
    await expectLater(
      boundedDownload(
        transport,
        Uri.parse('$base/media/slow-body'),
        timeout: const Duration(milliseconds: 80),
        maxBytes: 100,
      ),
      throwsA(isA<TimeoutException>()),
    );
  }, skip: skip);
}
