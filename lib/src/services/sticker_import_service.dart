import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../data/sticker_repository.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/sticker_storage.dart';

class StickerImportService {
  StickerImportService({StickerRepository? repository})
      : _repo = repository ?? StickerRepository.instance;

  final StickerRepository _repo;

  static const _imageExts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
  static const _lottieExts = ['json', 'lottie'];
  static const _packExts = ['zip'];

  /// Pick images/GIFs and add them to the custom favorites pack.
  Future<List<Sticker>> pickAndAddCustomStickers() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: '添加自定义表情',
      type: FileType.custom,
      allowedExtensions: [..._imageExts, ..._lottieExts],
    );
    if (files == null || files.files.isEmpty) return const [];

    final added = <Sticker>[];
    for (final file in files.files) {
      final bytes = await file.xFile.readAsBytes();
      final ext =
          (file.extension ?? p.extension(file.name).replaceFirst('.', ''))
              .toLowerCase();
      final id = _repo.newId();
      final filename = '$id.${ext.isEmpty ? 'png' : ext}';
      final ref = await StickerStorage.saveBytes(
        packId: 'custom',
        filename: filename,
        bytes: bytes,
      );
      final sticker = await _repo.addStickerToCustom(
        name: p.basenameWithoutExtension(file.name),
        kind: StickerKind.fromExtension(ext),
        localPath: ref,
      );
      added.add(sticker);
    }
    return added;
  }

  /// Pick a zip pack or a single sticker file and import it.
  Future<StickerPack?> pickAndImportPack() async {
    final file = await FilePicker.pickFile(
      dialogTitle: '导入表情包',
      type: FileType.custom,
      allowedExtensions: [..._packExts, ..._imageExts, ..._lottieExts],
    );
    if (file == null) return null;

    final bytes = await file.xFile.readAsBytes();
    final ext =
        (file.extension ?? p.extension(file.name).replaceFirst('.', ''))
            .toLowerCase();

    if (ext == 'zip') {
      return _importZip(bytes, fallbackName: p.basenameWithoutExtension(file.name));
    }

    final packId = _repo.newId();
    final filename = 'sticker.${ext.isEmpty ? 'png' : ext}';
    final ref = await StickerStorage.saveBytes(
      packId: packId,
      filename: filename,
      bytes: bytes,
    );
    final sticker = Sticker(
      id: _repo.newId(),
      packId: packId,
      name: p.basenameWithoutExtension(file.name),
      kind: StickerKind.fromExtension(ext),
      localPath: ref,
      createdAt: DateTime.now(),
    );
    final pack = StickerPack(
      id: packId,
      name: sticker.name,
      source: StickerSource.imported,
      coverPath: ref,
      stickers: [sticker],
    );
    await _repo.savePack(pack);
    return pack;
  }

  Future<StickerPack> _importZip(
    List<int> bytes, {
    required String fallbackName,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final packId = _repo.newId();

    Map<String, dynamic>? manifest;
    final extracted = <String, Uint8List>{};

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll('\\', '/');
      if (name.contains('__MACOSX') || name.endsWith('.DS_Store')) continue;
      final base = p.basename(name);
      final content = Uint8List.fromList(entry.content as List<int>);
      extracted[base] = content;
      if (base.toLowerCase() == 'manifest.json') {
        manifest = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
      }
    }

    final stickers = <Sticker>[];
    var packName = fallbackName;

    if (manifest != null) {
      packName = manifest['name'] as String? ?? fallbackName;
      final list = manifest['stickers'] as List<dynamic>? ?? const [];
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        final fileName = map['file'] as String;
        final data = extracted[p.basename(fileName)];
        if (data == null) continue;
        final ext = p.extension(fileName).replaceFirst('.', '');
        final kindName = map['kind'] as String?;
        final ref = await StickerStorage.saveBytes(
          packId: packId,
          filename: p.basename(fileName),
          bytes: data,
        );
        stickers.add(
          Sticker(
            id: _repo.newId(),
            packId: packId,
            name: map['name'] as String? ??
                p.basenameWithoutExtension(fileName),
            kind: kindName != null
                ? StickerKind.fromName(kindName)
                : StickerKind.fromExtension(ext),
            localPath: ref,
            createdAt: DateTime.now(),
          ),
        );
      }
    } else {
      for (final entry in extracted.entries) {
        final name = entry.key.toLowerCase();
        if (name == 'manifest.json') continue;
        final ext = p.extension(entry.key).replaceFirst('.', '');
        if (![..._imageExts, ..._lottieExts].contains(ext.toLowerCase())) {
          continue;
        }
        final ref = await StickerStorage.saveBytes(
          packId: packId,
          filename: entry.key,
          bytes: entry.value,
        );
        stickers.add(
          Sticker(
            id: _repo.newId(),
            packId: packId,
            name: p.basenameWithoutExtension(entry.key),
            kind: StickerKind.fromExtension(ext),
            localPath: ref,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    if (stickers.isEmpty) {
      await StickerStorage.deletePackDir(packId);
      throw StateError('表情包中没有可用的表情文件');
    }

    final pack = StickerPack(
      id: packId,
      name: packName,
      source: StickerSource.imported,
      coverPath: stickers.first.localPath,
      stickers: stickers,
    );
    await _repo.savePack(pack);
    return pack;
  }
}
