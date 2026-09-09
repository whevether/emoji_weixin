# emoji_weixin

[English](README.md) | [简体中文](README.zh-CN.md)

WeChat-style Flutter emoji/sticker panel package.

**Requirements:** Dart 3.12+ / Flutter 3.44+. Uses standalone [`material_ui`](https://pub.dev/packages/material_ui) (`package:material_ui/material_ui.dart`) instead of `package:flutter/material.dart`. Host apps should do the same; wrap unmigrated third-party Material widgets with `MaterialUiCompatibilityBridge`.

Features:

1. **Klipy online search** — download and save results as local favorites  
2. **Built-in emoji** — Unicode emoji + recently used, plus Douyin common stickers  
3. **Custom stickers** — gallery pick via `image_picker`; static images open `pro_image_editor`, GIFs are added as-is  
4. **Capture & edit** — iOS/Android only: system camera → `pro_image_editor`  
5. **Multi-language UI** — `EmojiWeixinConfig.locale` (`zh` / `en` / `vi` / `id` / `fil` / `ms` / `hi`)

## Demo

Example app screen recording (Klipy search, send, right-click to favorite):

<video src="example/demo/emoji_weixin_demo.mp4" controls width="720"></video>

- [`example/demo/emoji_weixin_demo.mp4`](example/demo/emoji_weixin_demo.mp4)

## Platform support

| Feature | iOS | Android | Web | macOS | Windows | Linux |
|---------|-----|---------|-----|-------|---------|-------|
| Panel / recent / Douyin stickers | Yes | Yes | Yes | Yes | Yes | Yes |
| image_picker add/edit | Yes | Yes | Yes | Yes | Yes | Yes |
| Klipy search & save | Yes | Yes | Yes | Yes | Yes | Yes |
| Capture & edit | System camera | System camera | — | — | — | — |

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
  const EmojiWeixinConfig(
    klipyApiKey: 'YOUR_KLIPY_API_KEY',
    locale: EmojiWeixinLocale.en, // zh en vi id fil ms hi
  ),
);

EmojiWeixinPanel(
  onStickerSelected: (sticker) {
    // insert into chat, etc.
  },
);

// Option 2: pass config per panel
EmojiWeixinPanel(
  config: const EmojiWeixinConfig(klipyApiKey: 'YOUR_KLIPY_API_KEY'),
  onStickerSelected: (sticker) {},
);
```

## Run the example

```bash
cd example
# Edit assets/config.json and set klipyApiKey
flutter pub get
flutter run                      # or -d chrome / macos / windows / linux
```

## Douyin sticker assets (disclaimer)

Built-in Douyin stickers are synced from:

- Site: <https://hnlyzxf.github.io/douyin-emoji/>
- Repo: <https://github.com/hnlyzxf/douyin-emoji>

Asset copyright belongs to Douyin / rights holders. **For learning and exchange only — do not use commercially.** Package code is MIT; Douyin media assets are not covered by MIT.

Assets live under `assets/stickers/douyin/` (`info.json` + `static/`).

## Klipy API key

Pass the key through configuration (**not** `--dart-define`):

1. Create a key at [KLIPY Partner Panel](https://partner.klipy.com) ([docs](https://docs.klipy.com/getting-started))  
2. Host app: `EmojiWeixinConfig.configure(...)` or panel `config:`  
3. Example app: edit [`example/assets/config.json`](example/assets/config.json) (see `config.example.json`)  
4. Show KLIPY attribution in your UI when using search ([attribution](https://docs.klipy.com/attribution))

```json
{
  "klipyApiKey": "YOUR_KEY"
}
```

If the key is missing or empty, the search tab is hidden; other features still work.

## Android (example)

Aligned with [kinetic_player/example](https://github.com/wanwenfeng4798/kinetic_player/tree/main/example):

- `compileSdk` / `targetSdk`: **37**
- `minSdk`: 24
- AGP: **9.3.1**
- Kotlin: **2.4.10**
- Gradle: **9.6.1**
- Release signing: [`example/android/key.properties`](example/android/key.properties) + [`example/jks/emoji_weixin.jks`](example/jks/emoji_weixin.jks) (demo keystore; replace for production)
- Release minify/shrink + [`proguard-rules.pro`](example/android/app/proguard-rules.pro)

## Platform permissions

### iOS

- `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription`

### Android

- `CAMERA` / `INTERNET` / `READ_MEDIA_IMAGES`

### macOS

- App Sandbox + `network.client` + `files.user-selected.read-write`

## Main APIs

| API | Description |
|-----|-------------|
| `EmojiWeixinConfig` | App/panel configuration (Klipy key, `locale`) |
| `EmojiWeixinLocale` | UI language: China/USA/Vietnam/Indonesia/Philippines/Malaysia/India |
| `EmojiWeixinPanel` | WeChat-style bottom sticker panel |
| `StickerRepository` | Pack/favorites persistence (Hive) |
| `StickerImportService` | Gallery add/edit via `image_picker` |
| `CameraStickerService` | Capture + edit (mobile) |
| `KlipyClient` / `KlipyStickerService` | Search and download |
| `StickerRenderer` | PNG/GIF/Unicode rendering |

## Docs

- English (default): [README.md](README.md), [CHANGELOG.md](CHANGELOG.md)
- Simplified Chinese: [README.zh-CN.md](README.zh-CN.md), [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)

## License

MIT (does not include Douyin sticker asset copyright)
