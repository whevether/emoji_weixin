import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'image_format.dart';

/// Downloads a response with a deadline and a bounded in-memory body.
Future<({Uint8List bytes, String? contentType})> boundedDownload(
  http.Client client,
  Uri uri, {
  required Duration timeout,
  required int maxBytes,
  bool requireHttps = false,
}) async {
  if (!{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
    throw ArgumentError('Expected an HTTP or HTTPS URL');
  }
  if (requireHttps && uri.scheme != 'https') {
    throw ArgumentError('Expected an HTTPS URL');
  }
  if (maxBytes <= 0 || timeout <= Duration.zero) {
    throw ArgumentError('Download limits must be positive');
  }
  final abort = Completer<void>();
  final abortable = http.AbortableRequest(
    'GET',
    uri,
    abortTrigger: abort.future,
  );
  final elapsed = Stopwatch()..start();
  Timer? timer;
  StreamIterator<List<int>>? chunks;
  try {
    timer = Timer(timeout, () {
      if (!abort.isCompleted) abort.complete();
    });
    final response = await client.send(abortable).timeout(timeout);
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    if ((response.contentLength ?? 0) > maxBytes) {
      throw StateError('Response exceeds $maxBytes bytes');
    }
    final result = BytesBuilder(copy: false);
    chunks = StreamIterator(response.stream);
    while (await chunks.moveNext().timeout(timeout - elapsed.elapsed)) {
      final chunk = chunks.current;
      if (result.length + chunk.length > maxBytes) {
        throw StateError('Response exceeds $maxBytes bytes');
      }
      result.add(chunk);
    }
    return (
      bytes: result.takeBytes(),
      contentType: response.headers['content-type'],
    );
  } on http.RequestAbortedException {
    throw TimeoutException('Request timed out', timeout);
  } on http.ClientException {
    throw StateError('Network request failed');
  } finally {
    timer?.cancel();
    if (!abort.isCompleted) abort.complete();
    await chunks?.cancel();
  }
}

/// Detects supported raster formats from bytes rather than a URL suffix.
String stickerExtension(Uint8List bytes, String? contentType) {
  final mime = contentType?.split(';').first.trim().toLowerCase();
  if (mime != null &&
      mime.isNotEmpty &&
      !mime.startsWith('image/') &&
      mime != 'application/octet-stream') {
    throw const FormatException('Response is not an image');
  }
  final ext = sniffImageExtension(bytes);
  if (!isRenderableExtension(ext)) {
    throw const FormatException('Unsupported or invalid image data');
  }
  return ext!;
}
