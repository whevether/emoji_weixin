import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// IO implementation of sticker byte storage (mobile / desktop).
class StickerStorageImpl {
  static String? _root;

  /// Ensures the app documents storage root exists.
  static Future<void> init() async {
    if (_root != null) return;
    final docs = await getApplicationDocumentsDirectory();
    _root = p.join(docs.path, 'emoji_weixin');
    await Directory(_root!).create(recursive: true);
  }

  static String get _ensureRoot {
    final root = _root;
    if (root == null) {
      throw StateError('StickerStorage not initialized');
    }
    return root;
  }

  /// Writes [bytes] under the pack directory and returns the file path.
  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final dir = Directory(p.join(_ensureRoot, 'packs', packId, 'files'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Reads a local file path; returns `null` for `hive:` refs or missing files.
  static Future<Uint8List?> readBytes(String ref) async {
    if (ref.startsWith('hive:')) return null;
    final file = File(ref);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Deletes the on-disk directory for [packId].
  static Future<void> deletePackDir(String packId) async {
    final dir = Directory(p.join(_ensureRoot, 'packs', packId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Absolute storage root, or empty before [init].
  static String rootHint() => _root ?? '';
}
