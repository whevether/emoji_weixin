import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:material_ui/material_ui.dart';

import '../klipy/klipy_client.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import 'sticker_preview.dart';

/// Klipy search / trending tab for the sticker panel.
class KlipySearchTab extends StatefulWidget {
  /// Creates the search tab.
  const KlipySearchTab({
    super.key,
    required this.client,
    required this.strings,
    required this.onSelected,
  });

  /// Klipy HTTP client.
  final KlipyClient client;

  /// Localized UI strings.
  final EmojiWeixinStrings strings;

  /// Called when the user picks a search result.
  final void Function(Sticker sticker) onSelected;

  /// Creates the mutable state for this tab.
  @override
  State<KlipySearchTab> createState() => _KlipySearchTabState();
}

class _KlipySearchTabState extends State<KlipySearchTab> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _stickersMode = true;
  int _requestId = 0;
  bool _loading = false;
  String? _error;
  List<KlipyGifItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant KlipySearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client) {
      _debounce?.cancel();
      _load(_controller.text);
    }
  }

  static const _perPage = 24;
  final _scroll = ScrollController();
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _moreFailed = false;

  Future<List<KlipyGifItem>> _fetch(String term, int page) {
    final client = widget.client;
    final stickers = _stickersMode;
    return term.isEmpty
        ? (stickers
              ? client.trendingStickers(page: page, perPage: _perPage)
              : client.trendingGifs(page: page, perPage: _perPage))
        : (stickers
              ? client.searchStickers(
                  query: term,
                  page: page,
                  perPage: _perPage,
                )
              : client.searchGifs(query: term, page: page, perPage: _perPage));
  }

  Future<void> _load([String query = '']) async {
    final requestId = ++_requestId;
    final term = query.trim();
    setState(() {
      _loading = true;
      _loadingMore = false;
      _moreFailed = false;
      _error = null;
    });
    try {
      final items = await _fetch(term, 1);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = items;
        _page = 1;
        // A short page means the end; avoids one extra empty request.
        _hasMore = items.length >= _perPage;
        _moreFailed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = widget.strings.searchFailedMessage;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    if (_moreFailed) return;
    final requestId = _requestId;
    final next = _page + 1;
    setState(() => _loadingMore = true);
    try {
      final more = await _fetch(_controller.text.trim(), next);
      if (!mounted || requestId != _requestId) return;
      final seen = _items.map((e) => e.id).toSet();
      final fresh = more.where((e) => seen.add(e.id)).toList();
      setState(() {
        _items = [..._items, ...fresh];
        _page = next;
        _hasMore = fresh.isNotEmpty && more.length >= _perPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      // Keep the loaded items and scroll position; Retry only refetches
      // the failed page.
      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 200) _loadMore();
    return false;
  }

  Sticker _toSticker(KlipyGifItem item) => Sticker(
    id: item.id,
    packId: 'klipy',
    name: item.title,
    kind: StickerKind.gif,
    networkUrl: item.originalUrl,
  );

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    // Invalidate the old response immediately, including the debounce window.
    _requestId++;
    setState(() {
      _loading = false;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(value));
  }

  void _send(KlipyGifItem item) {
    // Send only — favorite via chat context menu (WeChat-like).
    widget.onSelected(_toSticker(item));
  }

  void _preview(KlipyGifItem item) {
    showStickerPreview(
      context,
      sticker: _toSticker(item),
      strings: widget.strings,
      onSend: widget.onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: widget.strings.searchHint,
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(widget.strings.stickers),
                  ),
                  ButtonSegment(value: false, label: Text(widget.strings.gifs)),
                ],
                selected: {_stickersMode},
                onSelectionChanged: (s) {
                  setState(() => _stickersMode = s.first);
                  _debounce?.cancel();
                  _load(_controller.text);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null || _moreFailed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error ?? widget.strings.searchFailedMessage,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_error == null && _moreFailed) {
                      setState(() => _moreFailed = false);
                      _loadMore();
                    } else {
                      _load(_controller.text);
                    }
                  },
                  child: Text(widget.strings.retry),
                ),
              ],
            ),
          ),
        Expanded(
          child: !_loading && _error == null && _items.isEmpty
              ? Center(child: Text(widget.strings.noResults))
              : NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Semantics(
                        button: true,
                        label: item.title,
                        child: InkWell(
                          onTap: () => _send(item),
                          onLongPress: () => _preview(item),
                          borderRadius: BorderRadius.circular(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ExtendedImage.network(
                              item.previewUrl,
                              fit: BoxFit.cover,
                              cache: true,
                              loadStateChanged: (state) {
                                switch (state.extendedImageLoadState) {
                                  case LoadState.loading:
                                    return ColoredBox(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  case LoadState.failed:
                                    return const Icon(
                                      Icons.broken_image_outlined,
                                    );
                                  case LoadState.completed:
                                    return null;
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (_loadingMore) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Powered by KLIPY',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}
