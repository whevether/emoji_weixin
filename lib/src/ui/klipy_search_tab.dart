import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../klipy/klipy_client.dart';
import '../models/sticker.dart';
import '../models/sticker_kind.dart';

class KlipySearchTab extends StatefulWidget {
  const KlipySearchTab({
    super.key,
    required this.client,
    required this.onSelected,
  });

  final KlipyClient client;
  final void Function(Sticker sticker) onSelected;

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
                    hintText: '搜索 Klipy 表情',
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
                segments: const [
                  ButtonSegment(value: true, label: Text('贴纸')),
                  ButtonSegment(value: false, label: Text('GIF')),
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
              '搜索失败（请检查 Klipy API Key）\n$_error',
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
                  child: CachedNetworkImage(
                    imageUrl: item.previewUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ColoredBox(
                      color: Color(0xFFEDEDED),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image_outlined),
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
