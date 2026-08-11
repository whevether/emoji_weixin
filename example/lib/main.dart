import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appConfig = await AppConfig.load();
  EmojiWeixinConfig.configure(
    EmojiWeixinConfig(giphyApiKey: appConfig.giphyApiKey),
  );
  runApp(const EmojiWeixinDemoApp());
}

class EmojiWeixinDemoApp extends StatelessWidget {
  const EmojiWeixinDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'emoji_weixin Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF07C160)),
        useMaterial3: true,
      ),
      home: const ChatDemoPage(),
    );
  }
}

class ChatDemoPage extends StatefulWidget {
  const ChatDemoPage({super.key});

  @override
  State<ChatDemoPage> createState() => _ChatDemoPageState();
}

class _ChatDemoPageState extends State<ChatDemoPage> {
  final _messages = <_ChatMessage>[
    _ChatMessage.text('你好，点下方表情按钮试试仿微信表情面板。'),
  ];
  final _textController = TextEditingController();
  bool _showPanel = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage.text(text));
      _textController.clear();
    });
  }

  void _onSticker(Sticker sticker) {
    setState(() {
      _messages.add(_ChatMessage.sticker(sticker));
      _showPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        title: const Text('表情包演示'),
        backgroundColor: const Color(0xFFEDEDED),
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // Stickers render without bubble background (WeChat-like).
                if (msg.sticker != null) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: 120,
                      height: 120,
                      child: StickerRenderer(sticker: msg.sticker!),
                    ),
                  );
                }
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxWidth: 240),
                    decoration: BoxDecoration(
                      color: const Color(0xFF95EC69),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(msg.text ?? ''),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(),
          if (_showPanel)
            EmojiWeixinPanel(
              onStickerSelected: _onSticker,
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showPanel
                    ? Icons.keyboard_alt_outlined
                    : Icons.emoji_emotions_outlined,
              ),
              onPressed: () => setState(() => _showPanel = !_showPanel),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '输入消息',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
                onTap: () => setState(() => _showPanel = false),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _sendText,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
              ),
              child: const Text('发送'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage.text(this.text) : sticker = null;
  _ChatMessage.sticker(this.sticker) : text = null;

  final String? text;
  final Sticker? sticker;
}
