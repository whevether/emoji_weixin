import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../config/emoji_weixin_config.dart';
import '../data/builtin_emoji_catalog.dart';
import '../data/douyin_sticker_catalog.dart';
import '../data/emoji_keywords.dart';
import '../data/sticker_repository.dart';
import '../klipy/klipy_client.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/platform_caps.dart';
import '../services/camera_sticker_service.dart';
import '../services/sticker_import_service.dart';
import '../widgets/sticker_renderer.dart';
import '../widgets/local_image.dart';
import 'sticker_manage_page.dart';
import 'klipy_search_tab.dart';
import 'sticker_preview.dart';

/// Called when the user picks a sticker from [EmojiWeixinPanel].
typedef StickerSelectedCallback = void Function(Sticker sticker);

/// WeChat-style bottom emoji/sticker panel.
class EmojiWeixinPanel extends StatefulWidget {
  /// Creates the sticker panel.
  const EmojiWeixinPanel({
    super.key,
    required this.onStickerSelected,
    this.config,
    this.height = 320,
    this.onDelete,
  });

  /// Invoked when a sticker is selected.
  final StickerSelectedCallback onStickerSelected;

  /// Called when the WeChat-style delete key is pressed. The key is hidden
  /// when null.
  final VoidCallback? onDelete;

  /// Panel config (e.g. Klipy key, locale). Falls back to [EmojiWeixinConfig.global].
  final EmojiWeixinConfig? config;

  /// Panel height in logical pixels.
  final double height;

  /// Creates the mutable state for this panel.
  @override
  State<EmojiWeixinPanel> createState() => _EmojiWeixinPanelState();
}

class _EmojiWeixinPanelState extends State<EmojiWeixinPanel> {
  final _repo = StickerRepository.instance;
  final _import = StickerImportService();
  final _camera = CameraStickerService();

  late List<_PanelTab> _tabs;
  int _tabIndex = 0;
  bool _ready = false;
  String? _error;
  KlipyClient? _klipy;
  List<Sticker> _recent = const [];
  late EmojiWeixinConfig _config;
  bool _searching = false;
  String _filter = '';

  EmojiWeixinStrings get _s => _config.strings;

  @override
  void initState() {
    super.initState();
    _config = EmojiWeixinConfig.resolve(widget.config);
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant EmojiWeixinPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _config = EmojiWeixinConfig.resolve(widget.config);
      if (_ready) {
        _syncKlipy();
        _rebuildTabs();
      }
    }
  }

  Future<void> _bootstrap() async {
    try {
      await _repo.init();
      if (!mounted) return;
      _config = EmojiWeixinConfig.resolve(widget.config);
      _syncKlipy();
      _rebuildTabs();
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString()); // shown only via friendly text
    }
  }

  void _syncKlipy() {
    final key = _config.resolvedKlipyApiKey;
    final locale = _config.locale.languageCode == 'zh'
        ? 'cn'
        : _config.locale.languageCode;
    StickerRepository.maxCustomStickers = _config.maxFavorites;
    final customer = _config.klipyCustomerId;
    if (_klipy?.apiKey == key &&
        (_klipy == null ||
            (_klipy!.locale == locale && _klipy!.customerId == customer))) {
      return;
    }
    _klipy?.close();
    _klipy = key == null
        ? null
        : KlipyClient(apiKey: key, locale: locale, customerId: customer);
  }

  String _packTitle(StickerPack pack) {
    if (pack.id == BuiltinEmojiCatalog.packId) return _s.emojiPack;
    if (pack.id == DouyinStickerCatalog.packId) return _s.douyinPack;
    if (pack.id == 'custom') return _s.favoritesPack;
    return pack.name;
  }

  void _rebuildTabs() {
    _recent = _repo.getRecentStickers();
    final packs = _repo.getAllPacks();
    final system = BuiltinEmojiCatalog.pack();
    _tabs = [
      _PanelTab.system(_packTitle(system), system),
      for (final pack in packs) _PanelTab.pack(_packTitle(pack), pack),
      if (_klipy != null) _PanelTab.search(_s.search),
    ];
    if (_tabIndex >= _tabs.length) _tabIndex = 0;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    _rebuildTabs();
    setState(() {});
  }

  void _select(Sticker sticker) {
    unawaited(_remember(sticker));
    widget.onStickerSelected(sticker);
  }

  Future<void> _remember(Sticker sticker) async {
    try {
      await _repo.recordRecent(sticker);
      if (!mounted) return;
      setState(() => _recent = _repo.getRecentStickers());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(_s.operationFailed(error))));
    }
  }

  @override
  void dispose() {
    _klipy?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_s.loadFailedMessage),
              TextButton(
                onPressed: () {
                  setState(() => _error = null);
                  _bootstrap();
                },
                child: Text(_s.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final tab = _tabs[_tabIndex];
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (d) {
                  // The search tab has a text field; drags there select text.
                  if (tab.isSearch || _searching) return;
                  final v = d.primaryVelocity ?? 0;
                  if (v < -300 && _tabIndex < _tabs.length - 1) {
                    setState(() => _tabIndex++);
                  } else if (v > 300 && _tabIndex > 0) {
                    setState(() => _tabIndex--);
                  }
                },
                child: _buildBody(tab),
              ),
            ),
            _buildPackBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (_searching)
            Expanded(
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _filter = v.trim()),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _s.emojiSearchHint,
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            )
          else ...[
            Text(
              _tabs[_tabIndex].title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
          ],
          if (!_tabs[_tabIndex].isSearch)
            IconButton(
              tooltip: _s.emojiSearchHint,
              icon: Icon(
                _searching ? Icons.close : Icons.manage_search,
                size: 22,
              ),
              onPressed: () => setState(() {
                _searching = !_searching;
                _filter = '';
              }),
            ),
          if (_recent.isNotEmpty &&
              _tabs[_tabIndex].pack?.id == BuiltinEmojiCatalog.packId)
            IconButton(
              tooltip: _s.clearRecent,
              icon: const Icon(Icons.history_toggle_off, size: 22),
              onPressed: () async {
                await _repo.clearRecent();
                await _refresh();
              },
            ),
          if (widget.onDelete != null)
            IconButton(
              tooltip: _s.deleteKey,
              icon: const Icon(Icons.backspace_outlined, size: 22),
              onPressed: widget.onDelete,
            ),
          IconButton(
            tooltip: _s.addTooltip,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: _showAddMenu,
          ),
          IconButton(
            tooltip: _s.manageTooltip,
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StickerManagePage(strings: _s),
                ),
              );
              await _refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(_PanelTab tab) {
    if (tab.isSearch) {
      return KlipySearchTab(
        key: ObjectKey(_klipy),
        client: _klipy!,
        strings: _s,
        onSelected: _select,
      );
    }

    final pack = tab.pack!;
    final isEmoji = pack.id == BuiltinEmojiCatalog.packId;
    if (_searching && _filter.isNotEmpty) {
      final q = _filter.toLowerCase();
      final hits = pack.stickers
          .where(
            (s) => isEmoji
                ? emojiMatches(s.unicode ?? '', q)
                : s.name.toLowerCase().contains(q),
          )
          .toList();
      if (hits.isEmpty) return Center(child: Text(_s.noMatches));
      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isEmoji ? 8 : 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: hits.length,
        itemBuilder: (context, i) => _cell(hits[i]),
      );
    }
    if (isEmoji) {
      return _buildEmojiTab(pack);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: pack.stickers.length,
      itemBuilder: (context, index) {
        final sticker = pack.stickers[index];
        return _cell(sticker);
      },
    );
  }

  Widget _cell(Sticker sticker) => Semantics(
    button: true,
    label: sticker.name.isEmpty ? sticker.unicode : sticker.name,
    child: InkWell(
      onTap: () => _select(sticker),
      onLongPress: () => showStickerPreview(
        context,
        sticker: sticker,
        strings: _s,
        onSend: _select,
        onFavorited: _refresh,
      ),
      borderRadius: BorderRadius.circular(8),
      child: StickerRenderer(sticker: sticker),
    ),
  );

  /// WeChat-like emoji tab: recently used + full unicode list.
  Widget _buildEmojiTab(StickerPack pack) {
    final recentEmoji = _recent
        .where((s) => s.kind == StickerKind.unicode)
        .toList();
    final recentImages = _recent
        .where((s) => s.kind != StickerKind.unicode)
        .toList();
    return CustomScrollView(
      slivers: [
        if (recentImages.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _cell(recentImages[index]),
                childCount: recentImages.length,
              ),
            ),
          ),
        if (recentEmoji.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                _s.recentUsed,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return _cell(recentEmoji[index]);
              }, childCount: recentEmoji.length),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              _s.allEmoji,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final sticker = pack.stickers[index];
              return _cell(sticker);
            }, childCount: pack.stickers.length),
          ),
        ),
      ],
    );
  }

  Widget _buildPackBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final selected = index == _tabIndex;
          return Semantics(
            button: true,
            selected: selected,
            label: tab.title,
            child: InkWell(
              onTap: () => setState(() {
                _tabIndex = index;
                _searching = false;
                _filter = '';
              }),
              child: Container(
                width: 52,
                alignment: Alignment.center,
                color: selected
                    ? Theme.of(context).colorScheme.surfaceContainerLow
                    : Colors.transparent,
                child: tab.isSearch
                    ? Icon(
                        Icons.search,
                        color: selected
                            ? const Color(0xFF07C160)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : tab.pack!.id == BuiltinEmojiCatalog.packId
                    ? Text(
                        '☺',
                        style: TextStyle(
                          fontSize: 22,
                          color: selected
                              ? const Color(0xFF07C160)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      )
                    : tab.pack!.source == StickerSource.custom
                    ? const Text('💗', style: TextStyle(fontSize: 22))
                    : _packIcon(tab.pack!),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _packIcon(StickerPack pack) {
    if (pack.coverAsset != null) {
      return Image.asset(
        pack.coverAsset!,
        package: 'emoji_weixin',
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.folder, size: 22),
      );
    }
    if (pack.coverPath != null) {
      return SizedBox(
        width: 28,
        height: 28,
        child: LocalImage(
          ref: pack.coverPath!,
          width: 28,
          height: 28,
          errorBuilder: (_, _, _) => const Icon(Icons.folder, size: 22),
        ),
      );
    }
    if (pack.stickers.isEmpty) {
      return Icon(
        Icons.folder,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: StickerRenderer(sticker: pack.stickers.first),
    );
  }

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(_s.addEditImage),
              onTap: () => Navigator.pop(ctx, 'add'),
            ),
            if (PlatformCaps.supportsMobileCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(_s.captureSticker),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    // Fail before the user spends time picking and editing images.
    if (_repo.isFavoritesFull) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s.favoritesFull)));
      return;
    }

    try {
      switch (action) {
        case 'add':
          final added = await _import.pickAndAddCustomStickers(context);
          if (!mounted) return;
          if (added.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_s.addedCount(added.length))),
            );
            await _refresh();
          }
        case 'camera':
          final sticker = await _camera.captureAndEdit(context, strings: _s);
          if (!mounted) return;
          if (sticker != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(_s.savedCapture)));
            await _refresh();
          }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s.operationFailed(e))));
      await _refresh();
    }
  }
}

class _PanelTab {
  _PanelTab._({required this.title, this.pack, this.isSearch = false});

  factory _PanelTab.system(String title, StickerPack pack) =>
      _PanelTab._(title: title, pack: pack);

  factory _PanelTab.pack(String title, StickerPack pack) =>
      _PanelTab._(title: title, pack: pack);

  factory _PanelTab.search(String title) =>
      _PanelTab._(title: title, isSearch: true);

  final String title;
  final StickerPack? pack;
  final bool isSearch;
}
