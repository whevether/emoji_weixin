# 更新日志

[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-CN.md)

本文件记录本项目的重要变更。

## Unreleased

## 0.2.0

* Material 组件从 `package:flutter/material.dart` 切换为独立包 [`material_ui`](https://pub.dev/packages/material_ui) `^1.0.1`（`package:material_ui/material_ui.dart`）。需 Dart 3.12 / Flutter 3.44+。
* 对仍使用旧 Material 的第三方组件（`pro_image_editor`、`wechat_camera_picker`）使用 `MaterialUiCompatibilityBridge` 桥接。
* 在线搜索由 Giphy 切换为 [KLIPY](https://docs.klipy.com/)（`klipyApiKey` / `KlipyClient`）。

## 0.1.0

* 首次发布：仿微信表情面板，支持在线 GIF/贴纸搜索、`file_picker` 12.0.0-beta.7 自定义表情、`pro_image_editor` 拍摄/编辑，以及 GIF/Lottie 表情包导入。
* 内置抖音表情（学习交流用途，资源来自 hnlyzxf/douyin-emoji）。
* Unicode 表情 Tab +「最近使用」；移除图片占位「默认表情」包。
* 跨平台表情存储（IO 写文件，Web 使用 Hive 二进制）。
* Web/桌面通过 `FileType.image` 拍照或选图并编辑；iOS/Android 使用微信风格相机。
* 在线搜索 API Key 通过 `EmojiWeixinConfig` / `assets/config.json` 配置（不再使用 `--dart-define`）。
* example 支持 web/macOS/Windows/Linux；Android `compileSdk`/`targetSdk` 37（AGP 9.3.1、Gradle 9.6.1）。
* example Android Release 签名对齐 kinetic_player：`key.properties` + `example/jks/emoji_weixin.jks`。
* 文档：默认英文（`README.md`、`CHANGELOG.md`），另提供简体中文（`README.zh-CN.md`、`CHANGELOG.zh-CN.md`）。
