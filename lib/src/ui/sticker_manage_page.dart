import 'package:flutter/material.dart';

import '../data/sticker_repository.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../widgets/sticker_renderer.dart';

class StickerManagePage extends StatefulWidget {
  const StickerManagePage({super.key});

  @override
  State<StickerManagePage> createState() => _StickerManagePageState();
}

class _StickerManagePageState extends State<StickerManagePage> {
  final _repo = StickerRepository.instance;
  late List<StickerPack> _packs;

  @override
  void initState() {
    super.initState();
    _packs = _repo.getAllPacks();
  }

  void _reload() {
    setState(() => _packs = _repo.getAllPacks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('表情管理')),
      body: ListView.builder(
        itemCount: _packs.length,
        itemBuilder: (context, index) {
          final pack = _packs[index];
          return ExpansionTile(
            leading: SizedBox(
              width: 36,
              height: 36,
              child: pack.stickers.isEmpty
                  ? const Icon(Icons.folder_outlined)
                  : StickerRenderer(sticker: pack.stickers.first),
            ),
            title: Text(pack.name),
            subtitle: Text('${pack.source.name} · ${pack.stickers.length} 个'),
            children: [
              if (pack.source != StickerSource.builtin)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('重命名'),
                  onTap: () => _rename(pack),
                ),
              if (pack.source == StickerSource.imported ||
                  pack.source == StickerSource.klipy)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('删除表情包'),
                  onTap: () async {
                    await _repo.deletePack(pack.id);
                    _reload();
                  },
                ),
              ...pack.stickers.map(
                (s) => ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: StickerRenderer(sticker: s),
                  ),
                  title: Text(s.name),
                  subtitle: Text(s.kind.name),
                  trailing: pack.source == StickerSource.builtin
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _repo.removeSticker(pack.id, s.id);
                            _reload();
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rename(StickerPack pack) async {
    final controller = TextEditingController(text: pack.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名表情包'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _repo.renamePack(pack.id, name);
    _reload();
  }
}
