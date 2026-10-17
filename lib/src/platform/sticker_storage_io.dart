import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'storage_names.dart';

/// IO implementation of sticker byte storage (mobile / desktop).
class StickerStorageImpl {
  static String? _root;
  static Future<void>? _initializing;

  /// Ensures the app documents storage root exists.
  static Future<void> init() {
    if (_root != null) return Future.value();
    return _initializing ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final root = p.join(docs.path, 'emoji_weixin');
      await Directory(root).create(recursive: true);
      _root = root;
    } finally {
      _initializing = null;
    }
  }

  static Future<String> _managedPath(String path) async {
    final root = await Directory(p.join(_ensureRoot, 'packs'))
        .create(recursive: true);
    final rootPath = await root.resolveSymbolicLinks();
    final normalized = p.normalize(p.absolute(path));
    if (!p.isWithin(root.path, normalized)) {
      throw ArgumentError('Path is outside sticker storage');
    }
    // Resolve the closest existing ancestor too, so symlinks cannot escape.
    var ancestor = normalized;
    while (!await FileSystemEntity.type(
      ancestor,
      followLinks: false,
    ).then((type) => type != FileSystemEntityType.notFound)) {
      ancestor = p.dirname(ancestor);
    }
    final resolved = await File(ancestor).resolveSymbolicLinks();
    if (resolved != rootPath && !p.isWithin(rootPath, resolved)) {
      throw ArgumentError('Path resolves outside sticker storage');
    }
    return normalized;
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
    validateStorageName(packId, label: 'packId');
    validateStorageName(filename, label: 'filename');
    final dir = Directory(
      await _managedPath(p.join(_ensureRoot, 'packs', packId, 'files')),
    );
    await dir.create(recursive: true);
    final file = File(await _managedPath(p.join(dir.path, filename)));
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
    validateStorageName(packId, label: 'packId');
    final dir = Directory(
      await _managedPath(p.join(_ensureRoot, 'packs', packId)),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Deletes only files inside the managed packs directory.
  static Future<void> deleteBytes(String ref) async {
    final file = File(await _managedPath(ref));
    if (await file.exists()) await file.delete();
  }

  /// Absolute storage root, or empty before [init].
  static String rootHint() => _root ?? '';
}
