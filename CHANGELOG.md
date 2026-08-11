# Changelog

[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-CN.md)

All notable changes to this project are documented in this file.

## 0.1.0

* Initial release: WeChat-style sticker panel with Giphy search, custom stickers via `file_picker` 12.0.0-beta.7, capture/edit with `pro_image_editor`, and GIF/Lottie pack import.
* Built-in Douyin stickers (learning-only assets from hnlyzxf/douyin-emoji).
* Unicode emoji tab with recently used history; removed image-based placeholder default pack.
* Cross-platform sticker storage (filesystem on IO, Hive blobs on Web).
* Capture/edit on Web and desktop via `FileType.image`; WeChat camera on iOS/Android.
* Giphy API key via `EmojiWeixinConfig` / `assets/config.json` (not `--dart-define`).
* Example supports web/macOS/Windows/Linux; Android `compileSdk`/`targetSdk` 37 (AGP 9.3.1, Gradle 9.6.1).
* Example Android release signing via `key.properties` + `example/jks/emoji_weixin.jks` (kinetic_player-style).
* Docs: English default (`README.md`, `CHANGELOG.md`) plus Simplified Chinese (`README.zh-CN.md`, `CHANGELOG.zh-CN.md`).
