# Changelog

[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-CN.md)

All notable changes to this project are documented in this file.

## Unreleased

## 0.3.3

* Document the full public API (dartdoc) to meet pub.dev documentation scoring.
* Fix Flutter WebAssembly compatibility: stop defaulting `LocalImage` to a `dart:io` implementation; route WASM/web through the non-IO path.
* Use Hive web sticker storage on WASM via `dart.library.js_interop` (same as traditional web).

## 0.3.1

* Replace `cached_network_image` with [`extended_image`](https://pub.dev/packages/extended_image) `^10.1.0` for KLIPY search preview caching.

## 0.3.0

* Replace `wechat_camera_picker` and `file_picker` with [`image_picker`](https://pub.dev/packages/image_picker) `^1.2.3`; remove `archive` and `lottie`.
* Remove zip/Lottie pack import and `StickerKind.lottie`. Add menu is add/edit image (+ camera on iOS/Android only).
* Gallery static images open `pro_image_editor`; GIFs cannot keep animation in the editor so they are saved as-is.
* Multi-language UI via `EmojiWeixinConfig.locale` / `EmojiWeixinLocale`: `zh` (China), `en` (USA), `vi`, `id`, `fil`, `ms`, `hi`.

## 0.2.0

* Switch Material widgets from `package:flutter/material.dart` to standalone [`material_ui`](https://pub.dev/packages/material_ui) `^1.0.1` (`package:material_ui/material_ui.dart`). Requires Dart 3.12 / Flutter 3.44+.
* Wrap legacy third-party Material widgets (`pro_image_editor`, `wechat_camera_picker`) with `MaterialUiCompatibilityBridge`.
* Replace Giphy online search with [KLIPY](https://docs.klipy.com/) (`klipyApiKey` / `KlipyClient`).

## 0.1.0

* Initial release: WeChat-style sticker panel with online GIF/sticker search, custom stickers via `file_picker` 12.0.0-beta.7, capture/edit with `pro_image_editor`, and GIF/Lottie pack import.
* Built-in Douyin stickers (learning-only assets from hnlyzxf/douyin-emoji).
* Unicode emoji tab with recently used history; removed image-based placeholder default pack.
* Cross-platform sticker storage (filesystem on IO, Hive blobs on Web).
* Capture/edit on Web and desktop via `FileType.image`; WeChat camera on iOS/Android.
* Online search API key via `EmojiWeixinConfig` / `assets/config.json` (not `--dart-define`).
* Example supports web/macOS/Windows/Linux; Android `compileSdk`/`targetSdk` 37 (AGP 9.3.1, Gradle 9.6.1).
* Example Android release signing via `key.properties` + `example/jks/emoji_weixin.jks` (kinetic_player-style).
* Docs: English default (`README.md`, `CHANGELOG.md`) plus Simplified Chinese (`README.zh-CN.md`, `CHANGELOG.zh-CN.md`).
