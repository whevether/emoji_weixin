import 'dart:typed_data';

import 'package:hive_ce/hive_ce.dart';

class StickerStorageImpl {
  static const _boxName = 'emoji_weixin_blobs';
  static Box<Uint8List>? _box;

  static Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<Uint8List>(_boxName);
  }

  static Box<Uint8List> get _ensureBox {
    final box = _box;
    if (box == null) {
      throw StateError('StickerStorage not initialized');
    }
    return box;
  }

  static Future<String> saveBytes({
    required String packId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final key = '$packId/$filename';
    await _ensureBox.put(key, bytes);
    return 'hive:$key';
  }

  static Future<Uint8List?> readBytes(String ref) async {
    if (!ref.startsWith('hive:')) return null;
    final key = ref.substring('hive:'.length);
    return _ensureBox.get(key);
  }

  static Future<void> deletePackDir(String packId) async {
    final box = _ensureBox;
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith('$packId/'))
        .toList();
    for (final key in keys) {
      await box.delete(key);
    }
  }

  static String rootHint() => 'hive';
}
