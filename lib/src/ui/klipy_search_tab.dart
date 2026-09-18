import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:material_ui/material_ui.dart';

import '../klipy/klipy_client.dart';
import '../l10n/emoji_weixin_strings.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';

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
  bool _loading = false;
  String? _error;
  List<KlipyGifItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = _stickersMode
          ? await widget.client.trendingStickers()
          : await widget.client.trendingGifs();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      await _loadTrending();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = _stickersMode
          ? await widget.client.searchStickers(query: query.trim())
          : await widget.client.searchGifs(query: query.trim());
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  void _send(KlipyGifItem item) {
    // Send only — favorite via chat context menu (WeChat-like).
    widget.onSelected(
      Sticker(
        id: item.id,
        packId: 'klipy',
        name: item.title,
        kind: StickerKind.gif,
        networkUrl: item.originalUrl,
      ),
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
                    fillColor: Colors.white,
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
                  ButtonSegment(
                    value: false,
                    label: Text(widget.strings.gifs),
                  ),
                ],
                selected: {_stickersMode},
                onSelectionChanged: (s) {
                  setState(() => _stickersMode = s.first);
                  _search(_controller.text);
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
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.strings.searchFailed(_error!),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return InkWell(
                onTap: () => _send(item),
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
                          return const ColoredBox(
                            color: Color(0xFFEDEDED),
                            child: Center(
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
                          return const Icon(Icons.broken_image_outlined);
                        case LoadState.completed:
                          return null;
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Powered by KLIPY',
            style: TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ),
      ],
    );
  }
}
