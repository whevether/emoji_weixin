import 'package:material_ui/material_ui.dart';

import '../data/douyin_sticker_catalog.dart';
import '../data/sticker_repository.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
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
  final _selected = <String>{};
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
    appBar: AppBar(
      title: Text(_s.manageTitle),
      actions: [
        IconButton(
          tooltip: _s.newPack,
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: _busy ? null : _newPack,
        ),
        if (_selected.isNotEmpty) ...[
          IconButton(
            tooltip: _s.cancel,
            icon: const Icon(Icons.close),
            onPressed: () => setState(_selected.clear),
          ),
          IconButton(
            tooltip: _s.deleteKey,
            icon: const Icon(Icons.delete),
            onPressed: _busy ? null : _deleteSelected,
          ),
        ],
      ],
    ),
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
                    title: Text(_title(pack)),
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
                            : () async {
                                if (!await _confirm(1)) return;
                                await _run(() => _repo.deletePack(pack.id));
                              },
                      ),
                    ),
                  SliverReorderableList(
                    itemCount: pack.stickers.length,
                    onReorderItem: (oldIndex, newIndex) {
                      if (pack.source == StickerSource.builtin || _busy) return;
                      _run(
                        () =>
                            _repo.reorderStickers(pack.id, oldIndex, newIndex),
                      );
                    },
                    itemBuilder: (context, index) {
                      final sticker = pack.stickers[index];
                      final key = '${pack.id}/${sticker.id}';
                      final editable = pack.source != StickerSource.builtin;
                      return Material(
                        key: ValueKey(key),
                        type: MaterialType.transparency,
                        child: ListTile(
                          selected: _selected.contains(key),
                          onLongPress: editable
                              ? () => setState(() {
                                  if (!_selected.add(key)) {
                                    _selected.remove(key);
                                  }
                                })
                              : null,
                          onTap: _selected.isEmpty || !editable
                              ? null
                              : () => setState(() {
                                  if (!_selected.add(key)) {
                                    _selected.remove(key);
                                  }
                                }),
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: StickerRenderer(sticker: sticker),
                          ),
                          title: Text(sticker.name),
                          subtitle: Text(_s.kindLabel(sticker.kind.name)),
                          trailing: !editable
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<String>(
                                      enabled: !_busy,
                                      onSelected: (v) => v == 'rename'
                                          ? _renameSticker(pack, sticker)
                                          : _move(pack, sticker),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'rename',
                                          child: Text(_s.rename),
                                        ),
                                        PopupMenuItem(
                                          value: 'move',
                                          child: Text(_s.moveToPack),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      tooltip: _s.pinToTop,
                                      icon: const Icon(
                                        Icons.vertical_align_top,
                                      ),
                                      onPressed: _busy || index == 0
                                          ? null
                                          : () => _run(
                                              () => _repo.pinSticker(
                                                pack.id,
                                                sticker.id,
                                              ),
                                            ),
                                    ),
                                    IconButton(
                                      tooltip: _s.deleteKey,
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: _busy
                                          ? null
                                          : () async {
                                              if (!await _confirm(1)) return;
                                              await _run(
                                                () => _repo.removeSticker(
                                                  pack.id,
                                                  sticker.id,
                                                ),
                                              );
                                            },
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.drag_handle),
                                      ),
                                    ),
                                  ],
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

  String _title(StickerPack pack) {
    if (pack.id == 'custom') return _s.favoritesPack;
    if (pack.id == DouyinStickerCatalog.packId) return _s.douyinPack;
    return pack.name;
  }

  Future<bool> _confirm(int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(_s.confirmDelete(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.confirm),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _deleteSelected() async {
    if (!await _confirm(_selected.length)) return;
    final byPack = <String, List<String>>{};
    for (final key in _selected) {
      final i = key.indexOf('/');
      byPack
          .putIfAbsent(key.substring(0, i), () => [])
          .add(key.substring(i + 1));
    }
    _selected.clear();
    await _run(() async {
      for (final e in byPack.entries) {
        await _repo.removeStickers(e.key, e.value);
      }
    });
  }

  Future<String?> _askName(String title, String initial) => showDialog<String>(
    context: context,
    builder: (_) =>
        _RenamePackDialog(title: title, initial: initial, strings: _s),
  );

  Future<void> _rename(StickerPack pack) async {
    final name = await _askName(_s.renamePack, pack.name);
    if (!mounted || name == null || name.isEmpty || name == pack.name) return;
    await _run(() async {
      await _repo.renamePack(pack.id, name);
    });
  }

  Future<void> _newPack() async {
    final name = await _askName(_s.newPack, '');
    if (!mounted || name == null || name.isEmpty) return;
    await _run(() async {
      await _repo.createPack(name);
    });
  }

  Future<void> _renameSticker(StickerPack pack, Sticker sticker) async {
    final name = await _askName(_s.rename, sticker.name);
    if (!mounted || name == null || name.isEmpty || name == sticker.name) {
      return;
    }
    await _run(() => _repo.renameSticker(pack.id, sticker.id, name));
  }

  Future<void> _move(StickerPack from, Sticker sticker) async {
    final targets = _packs
        .where((p) => p.source != StickerSource.builtin && p.id != from.id)
        .toList();
    if (targets.isEmpty) return;
    final target = await showDialog<StickerPack>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(_s.moveToPack),
        children: [
          for (final t in targets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(_title(t)),
            ),
        ],
      ),
    );
    if (!mounted || target == null) return;
    await _run(() => _repo.moveSticker(from.id, target.id, sticker.id));
  }
}

class _RenamePackDialog extends StatefulWidget {
  const _RenamePackDialog({
    required this.title,
    required this.initial,
    required this.strings,
  });
  final String title;
  final String initial;
  final EmojiWeixinStrings strings;

  @override
  State<_RenamePackDialog> createState() => _RenamePackDialogState();
}

class _RenamePackDialogState extends State<_RenamePackDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
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
