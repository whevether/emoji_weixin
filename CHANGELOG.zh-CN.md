# 更新日志

[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-CN.md)

本文件记录本项目的重要变更。

## 0.4.0

* 将直接依赖更新到最新兼容稳定版，同步示例依赖锁文件，补齐 Cupertino 图标字体。
* 合并并发初始化、串行化修改并检查数据库结果；表情包与历史记录使用事务更新，清理无引用媒体并保留共享文件。
* 修复异步回调在组件销毁后更新状态、搜索响应乱序、运行时配置切换，以及历史写入失败阻止发送的问题。
* 为 HTTP 请求增加超时和大小限制，校验下载图片签名并释放自建客户端；统一相册、拍照和网络图片保存流程。
* 缓存解析后的表情包与 Blob 读取 Future，管理页改为按需构建，移除旧 Material 桥接；重复图片条目合并时保留别名元数据。
* copyWith 支持清空可空字段，旧公开入口以弃用标记保留兼容。
* 示例 API 配置迁入 Git 忽略的本地构建配置；最低系统版本对齐 Flutter 3.47：iOS 15、macOS 12。Android Debug 构建不再依赖 Release 签名配置。
* 补充数据库、界面、文件系统、浏览器存储及本地 Postman HTTP 回归测试。

## 0.3.4

* 用 [`tostore`](https://pub.dev/packages/tostore) `^3.5.1` 替换 Hive（`hive_ce` / `hive_ce_flutter`），用于表情包元数据和 Web/WASM 表情字节。旧 Hive 数据不会自动迁移。
* 要求 Dart 3.13+ / Flutter 3.47+。`material_ui` 升级到 `^1.6.0`，`pro_image_editor` 升级到 `^14.11.0`，`image_picker` 升级到 `^1.2.4`。
* example Android：`android.builtInKotlin=true`，AGP 9.4.2，Kotlin 2.4.21，Gradle 9.8.0，NDK `30.0.16248370`。

## 0.3.3

* 全量补充公开 API 的 dartdoc 注释，以满足 pub.dev 文档评分要求。
* 修复 Flutter WebAssembly 兼容性：`LocalImage` 不再默认落入含 `dart:io` 的实现，WASM/web 走非 IO 路径。
* WASM 通过 `dart.library.js_interop` 使用与传统 web 相同的 Hive 表情存储。

## 0.3.1

* 使用 [`extended_image`](https://pub.dev/packages/extended_image) `^10.1.0` 替代 `cached_network_image`，用于 KLIPY 搜索预览图缓存。

## 0.3.0

* 使用 [`image_picker`](https://pub.dev/packages/image_picker) `^1.2.3` 替代 `wechat_camera_picker` 与 `file_picker`；移除 `archive`、`lottie`。
* 移除 zip/Lottie 表情包导入与 `StickerKind.lottie`；添加菜单为添加/编辑图片（仅 iOS/Android 另有拍照）。
* 相册静态图进入 `pro_image_editor`；GIF 无法在编辑器中保留动图，故直接添加。
* 多语言 UI：通过 `EmojiWeixinConfig.locale` / `EmojiWeixinLocale` 配置，支持 `zh`（中国）、`en`（美国）、`vi`、`id`、`fil`、`ms`、`hi`。

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
