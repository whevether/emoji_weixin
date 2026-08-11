import 'package:flutter/material.dart';

import '../config/emoji_weixin_config.dart';
import '../data/builtin_emoji_catalog.dart';
import '../data/sticker_repository.dart';
import '../giphy/giphy_client.dart';
import '../giphy/giphy_sticker_service.dart';
import '../models/sticker.dart';
import '../models/sticker_pack.dart';
import '../models/sticker_source.dart';
import '../platform/platform_caps.dart';
import '../services/camera_sticker_service.dart';
import '../services/sticker_import_service.dart';
import '../widgets/sticker_renderer.dart';
import 'sticker_manage_page.dart';
import 'giphy_search_tab.dart';

typedef StickerSelectedCallback = void Function(Sticker sticker);

/// WeChat-style bottom emoji/sticker panel.
class EmojiWeixinPanel extends StatefulWidget {
  const EmojiWeixinPanel({
    super.key,
    required this.onStickerSelected,
    this.config,
    this.height = 320,
  });

  final StickerSelectedCallback onStickerSelected;

  /// Panel config (e.g. Giphy key). Falls back to [EmojiWeixinConfig.global].
  final EmojiWeixinConfig? config;
  final double height;

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
  GiphyClient? _giphy;
  GiphyStickerService? _giphyService;
  List<Sticker> _recent = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _repo.init();
      final config = EmojiWeixinConfig.resolve(widget.config);
      final key = config.resolvedGiphyApiKey;
      if (key != null) {
        _giphy = GiphyClient(apiKey: key);
        _giphyService = GiphyStickerService(client: _giphy!);
      }
      _rebuildTabs();
      setState(() => _ready = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _rebuildTabs() {
    _recent = _repo.getRecentStickers();
    final packs = _repo.getAllPacks();
    final system = BuiltinEmojiCatalog.pack();
    _tabs = [
      _PanelTab.system(system),
      for (final pack in packs) _PanelTab.pack(pack),
      if (_giphy != null) _PanelTab.search(),
    ];
    if (_tabIndex >= _tabs.length) _tabIndex = 0;
  }

  Future<void> _refresh() async {
    _rebuildTabs();
    setState(() {});
  }

  Future<void> _select(Sticker sticker) async {
    await _repo.recordRecent(sticker);
    _recent = _repo.getRecentStickers();
    if (mounted) setState(() {});
    widget.onStickerSelected(sticker);
  }

  @override
  void dispose() {
    _giphy?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('加载失败: $_error')),
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
            tooltip: '添加',
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: _showAddMenu,
          ),
          IconButton(
            tooltip: '管理',
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StickerManagePage()),
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
      return GiphySearchTab(
        client: _giphy!,
        onAddToFavorite: (item) async {
          final sticker = await _giphyService!.composeToFavorite(item);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已添加到收藏')),
            );
            await _refresh();
          }
          return sticker;
        },
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                '最近使用',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sticker = _recent[index];
                  return InkWell(
                    onTap: () => _select(sticker),
                    borderRadius: BorderRadius.circular(8),
                    child: StickerRenderer(sticker: sticker),
                  );
                },
                childCount: _recent.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              '所有表情',
              style: TextStyle(fontSize: 12, color: Colors.black54),
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sticker = pack.stickers[index];
                return InkWell(
                  onTap: () => _select(sticker),
                  borderRadius: BorderRadius.circular(8),
                  child: StickerRenderer(sticker: sticker),
                );
              },
              childCount: pack.stickers.length,
            ),
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
                      color: selected ? const Color(0xFF07C160) : Colors.black54,
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
              title: const Text('添加图片/GIF/Lottie'),
              onTap: () => Navigator.pop(ctx, 'add'),
            ),
            if (PlatformCaps.supportsCameraCapture)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(
                  PlatformCaps.supportsWechatCamera ? '拍自己的表情' : '拍照/选图并编辑',
                ),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: const Text('导入表情包'),
              onTap: () => Navigator.pop(ctx, 'import'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    try {
      switch (action) {
        case 'add':
          final added = await _import.pickAndAddCustomStickers();
          if (!mounted) return;
          if (added.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已添加 ${added.length} 个表情')),
            );
            await _refresh();
          }
        case 'camera':
          final sticker = await _camera.captureAndEdit(context);
          if (!mounted) return;
          if (sticker != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已保存拍照表情')),
            );
            await _refresh();
          }
        case 'import':
          final pack = await _import.pickAndImportPack();
          if (!mounted) return;
          if (pack != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已导入「${pack.name}」')),
            );
            await _refresh();
          }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }
}

class _PanelTab {
  _PanelTab._({
    required this.title,
    this.pack,
    this.isSearch = false,
  });

  factory _PanelTab.system(StickerPack pack) =>
      _PanelTab._(title: pack.name, pack: pack);

  factory _PanelTab.pack(StickerPack pack) =>
      _PanelTab._(title: pack.name, pack: pack);

  factory _PanelTab.search() => _PanelTab._(title: '搜索', isSearch: true);

  final String title;
  final StickerPack? pack;
  final bool isSearch;
}
