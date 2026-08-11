# emoji_weixin

[English](README.md) | [简体中文](README.zh-CN.md)

WeChat-style Flutter emoji/sticker panel package.

Features:

1. **Giphy online search** — download and save results as local favorites  
2. **Built-in emoji** — Unicode emoji + recently used, plus Douyin common stickers  
3. **Custom stickers** — add/manage via `file_picker` (PNG/JPG/WebP/GIF/Lottie)  
4. **Capture & edit** — iOS/Android: `wechat_camera_picker`; Web/desktop: `file_picker` `FileType.image` → `pro_image_editor`  
5. **Import packs** — zip or single files (PNG/JPG/WebP/GIF/Lottie)

## Platform support

| Feature | iOS | Android | Web | macOS | Windows | Linux |
|---------|-----|---------|-----|-------|---------|-------|
| Panel / recent / Douyin stickers | Yes | Yes | Yes | Yes | Yes | Yes |
| file_picker add/import | Yes | Yes | Yes | Yes | Yes | Yes |
| Giphy search & save | Yes | Yes | Yes | Yes | Yes | Yes |
| Capture/pick & edit | WeChat camera | WeChat camera | FileType.image | FileType.image | FileType.image | FileType.image |

## Quick start

```yaml
dependencies:
  emoji_weixin:
    path: ../ # or your dependency source
```

```dart
import 'package:emoji_weixin/emoji_weixin.dart';

// Option 1: global config at startup
EmojiWeixinConfig.configure(
  const EmojiWeixinConfig(giphyApiKey: 'YOUR_GIPHY_API_KEY'),
);

EmojiWeixinPanel(
  onStickerSelected: (sticker) {
    // insert into chat, etc.
  },
);

// Option 2: pass config per panel
EmojiWeixinPanel(
  config: const EmojiWeixinConfig(giphyApiKey: 'YOUR_GIPHY_API_KEY'),
  onStickerSelected: (sticker) {},
);
```

## Run the example

```bash
cd example
# Edit assets/config.json and set giphyApiKey
flutter pub get
flutter run                      # or -d chrome / macos / windows / linux
```

## Douyin sticker assets (disclaimer)

Built-in Douyin stickers are synced from:

- Site: <https://hnlyzxf.github.io/douyin-emoji/>
- Repo: <https://github.com/hnlyzxf/douyin-emoji>

Asset copyright belongs to Douyin / rights holders. **For learning and exchange only — do not use commercially.** Package code is MIT; Douyin media assets are not covered by MIT.

Assets live under `assets/stickers/douyin/` (`info.json` + `static/`).

## Giphy API key

Pass the key through configuration (**not** `--dart-define`):

1. Create a key at [Giphy Developers](https://developers.giphy.com/)  
2. Host app: `EmojiWeixinConfig.configure(...)` or panel `config:`  
3. Example app: edit [`example/assets/config.json`](example/assets/config.json) (see `config.example.json`)

```json
{
  "giphyApiKey": "YOUR_KEY"
}
```

If the key is missing or empty, the search tab is hidden; other features still work.

## Import pack format

Preferred zip layout with `manifest.json`:

```json
{
  "name": "Demo Pack",
  "id": "sample_demo",
  "stickers": [
    {"file": "smile.png", "name": "smile"},
    {"file": "spark.json", "name": "spark", "kind": "lottie"}
  ]
}
```

Sample pack: `example/assets/sample_pack.zip`.

## Android (example)

Aligned with [kinetic_player/example](https://github.com/wanwenfeng4798/kinetic_player/tree/main/example):

- `compileSdk` / `targetSdk`: **37**
- `minSdk`: 24
- AGP: **9.3.1**
- Kotlin: **2.4.10**
- Gradle: **9.6.1**
- `file_picker`: **12.0.0-beta.7** (AGP 9 compatible)
- Release signing: [`example/android/key.properties`](example/android/key.properties) + [`example/jks/emoji_weixin.jks`](example/jks/emoji_weixin.jks) (demo keystore; replace for production)
- Release minify/shrink + [`proguard-rules.pro`](example/android/app/proguard-rules.pro)

## Platform permissions

### iOS

- `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` / `NSPhotoLibraryUsageDescription`

### Android

- `CAMERA` / `INTERNET` / `READ_MEDIA_IMAGES`

### macOS

- App Sandbox + `network.client` + `files.user-selected.read-write`

## Main APIs

| API | Description |
|-----|-------------|
| `EmojiWeixinConfig` | App/panel configuration (e.g. Giphy key) |
| `EmojiWeixinPanel` | WeChat-style bottom sticker panel |
| `StickerRepository` | Pack/favorites persistence (Hive) |
| `StickerImportService` | Add/import via `file_picker` |
| `CameraStickerService` | Capture/pick + edit |
| `GiphyClient` / `GiphyStickerService` | Search and download |
| `StickerRenderer` | PNG/GIF/Lottie/Unicode rendering |

## Docs

- English (default): [README.md](README.md), [CHANGELOG.md](CHANGELOG.md)
- Simplified Chinese: [README.zh-CN.md](README.zh-CN.md), [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)

## License

MIT (does not include Douyin sticker asset copyright)
