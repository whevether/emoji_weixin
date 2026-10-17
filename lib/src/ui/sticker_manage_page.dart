import 'package:material_ui/material_ui.dart';

import '../data/sticker_repository.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../widgets/sticker_renderer.dart';

/// Full-screen page for renaming / deleting sticker packs.
class StickerManagePage extends StatefulWidget {
  /// Creates the manager page with localized strings.
  const StickerManagePage({super.key, required this.strings});

  /// UI copy for this page.
  final EmojiWeixinStrings strings;

  @override
  State<StickerManagePage> createState() => _StickerManagePageState();
}

class _StickerManagePageState extends State<StickerManagePage> {
  final _repo = StickerRepository.instance;
  final _expanded = <String>{};
  List<StickerPack> _packs = const [];
  bool _busy = true;
  EmojiWeixinStrings get _s => widget.strings;

  @override
  void initState() {
    super.initState();
    _run(_repo.init);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() => _packs = _repo.getAllPacks());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s.operationFailed(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_s.manageTitle)),
    body: Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              for (final pack in _packs) ...[
                SliverToBoxAdapter(
                  child: ListTile(
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
                    trailing: Icon(
                      _expanded.contains(pack.id)
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    onTap: () => setState(() {
                      if (!_expanded.add(pack.id)) _expanded.remove(pack.id);
                    }),
                  ),
                ),
                if (_expanded.contains(pack.id)) ...[
                  if (pack.source != StickerSource.builtin)
                    SliverToBoxAdapter(
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(_s.rename),
                        onTap: _busy ? null : () => _rename(pack),
                      ),
                    ),
                  if (pack.source == StickerSource.imported ||
                      pack.source == StickerSource.klipy)
                    SliverToBoxAdapter(
                      child: ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(_s.deletePack),
                        onTap: _busy
                            ? null
                            : () => _run(() => _repo.deletePack(pack.id)),
                      ),
                    ),
                  SliverList.builder(
                    itemCount: pack.stickers.length,
                    itemBuilder: (context, index) {
                      final sticker = pack.stickers[index];
                      return ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: StickerRenderer(sticker: sticker),
                        ),
                        title: Text(sticker.name),
                        subtitle: Text(sticker.kind.name),
                        trailing: pack.source == StickerSource.builtin
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                        () => _repo.removeSticker(
                                          pack.id,
                                          sticker.id,
                                        ),
                                      ),
                              ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _rename(StickerPack pack) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenamePackDialog(pack: pack, strings: _s),
    );
    if (!mounted || name == null || name.isEmpty || name == pack.name) return;
    await _run(() async {
      await _repo.renamePack(pack.id, name);
    });
  }
}

class _RenamePackDialog extends StatefulWidget {
  const _RenamePackDialog({required this.pack, required this.strings});
  final StickerPack pack;
  final EmojiWeixinStrings strings;

  @override
  State<_RenamePackDialog> createState() => _RenamePackDialogState();
}

class _RenamePackDialogState extends State<_RenamePackDialog> {
  late final _controller = TextEditingController(text: widget.pack.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.strings.renamePack),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.strings.nameHint),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.strings.cancel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: Text(widget.strings.confirm),
      ),
    ],
  );
}
