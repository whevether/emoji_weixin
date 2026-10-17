# Changelog

[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-CN.md)

All notable changes to this project are documented in this file.

## 0.4.0

* Upgrade direct dependencies to their latest compatible stable releases and synchronize the example lockfiles; add Cupertino icon fonts.
* Serialize initialization and mutations, check database outcomes, and atomically update pack metadata and recent history. Clean up unreferenced media while preserving shared files.
* Fix late asynchronous UI updates, stale search responses, runtime client configuration changes, and history failures blocking sticker sending.
* Bound HTTP responses by time and size, validate downloaded raster signatures, and release owned clients. Share media persistence across gallery, camera, and network imports.
* Cache decoded packs and blob futures, lazily build the manager, remove obsolete Material bridges, and preserve catalog aliases when consolidating duplicate image entries.
* Allow nullable fields to be cleared with copyWith; keep legacy public entry points deprecated for compatibility.
* Move example API settings to ignored local build configuration. Example platform minimums now match Flutter 3.47: iOS 15 and macOS 12; Android debug builds no longer require release signing settings.
* Add database, UI, filesystem, browser storage, and local Postman HTTP regression coverage.

## 0.3.4

* Replace Hive (`hive_ce` / `hive_ce_flutter`) with [`tostore`](https://pub.dev/packages/tostore) `^3.5.1` for pack metadata and Web/WASM sticker bytes. Existing Hive boxes are not migrated.
* Require Dart 3.13+ / Flutter 3.47+. Upgrade `material_ui` to `^1.6.0`, `pro_image_editor` to `^14.11.0`, and `image_picker` to `^1.2.4`.
* Example Android: `android.builtInKotlin=true`, AGP 9.4.2, Kotlin 2.4.21, Gradle 9.8.0, NDK `30.0.16248370`.

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
