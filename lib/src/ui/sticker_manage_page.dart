import 'package:material_ui/material_ui.dart';

import '../data/sticker_repository.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../widgets/sticker_renderer.dart';

/// Full-screen page for renaming / deleting sticker packs.
class StickerManagePage extends StatefulWidget {
  /// Creates the manager page with localized [strings].
  const StickerManagePage({
    super.key,
    required this.strings,
  });

  /// UI copy for this page.
  final EmojiWeixinStrings strings;

  /// Creates the mutable state for this page.
  @override
  State<StickerManagePage> createState() => _StickerManagePageState();
}

class _StickerManagePageState extends State<StickerManagePage> {
  final _repo = StickerRepository.instance;
  late List<StickerPack> _packs;

  EmojiWeixinStrings get _s => widget.strings;

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
      appBar: AppBar(title: Text(_s.manageTitle)),
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
            subtitle: Text(
              '${_s.sourceLabel(pack.source.name)} · ${_s.stickerCount(pack.stickers.length)}',
            ),
            children: [
              if (pack.source != StickerSource.builtin)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(_s.rename),
                  onTap: () => _rename(pack),
                ),
              if (pack.source == StickerSource.imported ||
                  pack.source == StickerSource.klipy)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(_s.deletePack),
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
        title: Text(_s.renamePack),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: _s.nameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(_s.confirm),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _repo.renamePack(pack.id, name);
    _reload();
  }
}
