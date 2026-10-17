import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../config/emoji_weixin_config.dart';
import '../data/builtin_emoji_catalog.dart';
import '../data/douyin_sticker_catalog.dart';
import '../data/sticker_repository.dart';
import '../klipy/klipy_client.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/platform_caps.dart';
import '../services/camera_sticker_service.dart';
import '../services/sticker_import_service.dart';
import '../widgets/sticker_renderer.dart';
import '../widgets/local_image.dart';
import 'sticker_manage_page.dart';
import 'klipy_search_tab.dart';

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
  });

  /// Invoked when a sticker is selected.
  final StickerSelectedCallback onStickerSelected;

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
      setState(() => _error = e.toString());
    }
  }

  void _syncKlipy() {
    final key = _config.resolvedKlipyApiKey;
    final locale = _config.locale.languageCode == 'zh'
        ? 'cn'
        : _config.locale.languageCode;
    if (_klipy?.apiKey == key && (_klipy == null || _klipy!.locale == locale)) {
      return;
    }
    _klipy?.close();
    _klipy = key == null ? null : KlipyClient(apiKey: key, locale: locale);
  }

  String _packTitle(StickerPack pack) {
    if (pack.id == BuiltinEmojiCatalog.packId) return _s.emojiPack;
    if (pack.id == DouyinStickerCatalog.packId) return _s.douyinPack;
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
        child: Center(child: Text(_s.loadFailed(_error!))),
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
      color: const Color(0xFFF7F7F7),
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
            _buildToolbar(),
            Expanded(child: _buildBody(tab)),
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
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          Text(
            _tabs[_tabIndex].title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
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
        return InkWell(
          onTap: () => _select(sticker),
          borderRadius: BorderRadius.circular(8),
          child: StickerRenderer(sticker: sticker),
        );
      },
    );
  }

  /// WeChat-like emoji tab: recently used + full unicode list.
  Widget _buildEmojiTab(StickerPack pack) {
    return CustomScrollView(
      slivers: [
        if (_recent.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                _s.recentUsed,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                final sticker = _recent[index];
                return InkWell(
                  onTap: () => _select(sticker),
                  borderRadius: BorderRadius.circular(8),
                  child: StickerRenderer(sticker: sticker),
                );
              }, childCount: _recent.length),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              _s.allEmoji,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
              return InkWell(
                onTap: () => _select(sticker),
                borderRadius: BorderRadius.circular(8),
                child: StickerRenderer(sticker: sticker),
              );
            }, childCount: pack.stickers.length),
          ),
        ),
      ],
    );
  }

  Widget _buildPackBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final selected = index == _tabIndex;
          return InkWell(
            onTap: () => setState(() => _tabIndex = index),
            child: Container(
              width: 52,
              alignment: Alignment.center,
              color: selected ? const Color(0xFFF7F7F7) : Colors.transparent,
              child: tab.isSearch
                  ? Icon(
                      Icons.search,
                      color: selected
                          ? const Color(0xFF07C160)
                          : Colors.black54,
                    )
                  : tab.pack!.id == BuiltinEmojiCatalog.packId
                  ? Text(
                      '☺',
                      style: TextStyle(
                        fontSize: 22,
                        color: selected
                            ? const Color(0xFF07C160)
                            : Colors.black87,
                      ),
                    )
                  : tab.pack!.source == StickerSource.custom
                  ? const Text('💗', style: TextStyle(fontSize: 22))
                  : _packIcon(tab.pack!),
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
      return const Icon(Icons.folder, size: 22, color: Colors.black54);
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
