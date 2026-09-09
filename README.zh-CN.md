# emoji_weixin

[English](README.md) | [简体中文](README.zh-CN.md)

仿微信风格的 Flutter 表情/贴纸面板 Package。

**环境要求：** Dart 3.12+ / Flutter 3.44+。使用独立包 [`material_ui`](https://pub.dev/packages/material_ui)（`package:material_ui/material_ui.dart`），不再直接 import `package:flutter/material.dart`。宿主 App 建议同样迁移；对尚未迁移的第三方 Material 组件使用 `MaterialUiCompatibilityBridge` 桥接。

功能：

1. **Klipy 在线搜索**并下载合成为本地收藏表情  
2. **常规表情**（Unicode 表情 +「最近使用」、抖音常用表情）  
3. **自定义表情**（`image_picker` 选图；静态图进 `pro_image_editor`，GIF 直接添加）  
4. **拍自己的表情**（仅 iOS/Android：系统相机 → `pro_image_editor`）  
5. **多语言 UI**（`EmojiWeixinConfig.locale`：`zh` / `en` / `vi` / `id` / `fil` / `ms` / `hi`）

## 演示

示例应用录屏（Klipy 搜索、发送、右键收藏）：

<video src="example/demo/emoji_weixin_demo.mp4" controls width="720"></video>

- [`example/demo/emoji_weixin_demo.mp4`](example/demo/emoji_weixin_demo.mp4)

## 平台支持

| 能力 | iOS | Android | Web | macOS | Windows | Linux |
|------|-----|---------|-----|-------|---------|-------|
| 表情面板 / 最近使用 / 抖音表情 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| image_picker 添加/编辑 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| Klipy 搜索合成 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| 拍照编辑 | 系统相机 | 系统相机 | — | — | — | — |

## 快速开始

```yaml
dependencies:
  emoji_weixin:
    path: ../ # 或你的依赖方式
```

```dart
import 'package:emoji_weixin/emoji_weixin.dart';

// 方式 1：启动时全局配置
EmojiWeixinConfig.configure(
  const EmojiWeixinConfig(
    klipyApiKey: '你的 Klipy API Key',
    locale: EmojiWeixinLocale.zh, // zh en vi id fil ms hi
  ),
);

EmojiWeixinPanel(
  onStickerSelected: (sticker) {
    // 插入聊天消息等
  },
);

// 方式 2：按面板传入
EmojiWeixinPanel(
  config: const EmojiWeixinConfig(klipyApiKey: '你的 Klipy API Key'),
  onStickerSelected: (sticker) {},
);
```

## 运行 example

```bash
cd example
# 编辑 assets/config.json，填入 klipyApiKey
flutter pub get
flutter run                      # 或 -d chrome / macos / windows / linux
```

## 抖音表情来源（免责声明）

内置「抖音表情」资源同步自开源静态库：

- 站点：<https://hnlyzxf.github.io/douyin-emoji/>
- 仓库：<https://github.com/hnlyzxf/douyin-emoji>

素材版权归抖音及相关权利方所有，**仅供学习交流，请勿商用**。本项目代码 MIT；抖音素材不在 MIT 授权范围内。

资源位置：`assets/stickers/douyin/`（`info.json` + `static/`）。

## Klipy API Key

通过配置传递，**不再使用** `--dart-define`：

1. 到 [KLIPY Partner Panel](https://partner.klipy.com) 创建 Key（[文档](https://docs.klipy.com/getting-started)）  
2. 宿主 App：`EmojiWeixinConfig.configure(...)` 或面板参数 `config:`  
3. example：编辑 [`example/assets/config.json`](example/assets/config.json)（可参考 `config.example.json`）  
4. 使用搜索时需展示 KLIPY 品牌标识（[attribution](https://docs.klipy.com/attribution)）

```json
{
  "klipyApiKey": "你的Key"
}
```

未配置或为空时，搜索 Tab 不显示，其余功能可用。

## Android 配置（example）

对齐 [kinetic_player/example](https://github.com/wanwenfeng4798/kinetic_player/tree/main/example)：

- `compileSdk` / `targetSdk`：**37**
- `minSdk`：24
- AGP：**9.3.1**
- Kotlin：**2.4.10**
- Gradle：**9.6.1**
- Release 签名：[`example/android/key.properties`](example/android/key.properties) + [`example/jks/emoji_weixin.jks`](example/jks/emoji_weixin.jks)（演示用证书，生产请自行替换）
- Release 开启混淆压缩 + [`proguard-rules.pro`](example/android/app/proguard-rules.pro)

## 平台权限

### iOS

- `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription`

### Android

- `CAMERA` / `INTERNET` / `READ_MEDIA_IMAGES`

### macOS

- App Sandbox + `network.client` + `files.user-selected.read-write`

## 主要 API

| API | 说明 |
|-----|------|
| `EmojiWeixinConfig` | 应用/面板配置（Klipy Key、`locale`） |
| `EmojiWeixinLocale` | UI 语种：中国/美国/越南/印尼/菲律宾/马来西亚/印度 |
| `EmojiWeixinPanel` | 仿微信底部表情面板 |
| `StickerRepository` | 表情包/收藏持久化（Hive） |
| `StickerImportService` | `image_picker` 添加/编辑 |
| `CameraStickerService` | 拍照 + 编辑（移动端） |
| `KlipyClient` / `KlipyStickerService` | 搜索与下载合成 |
| `StickerRenderer` | PNG/GIF/Unicode 统一渲染 |

## 文档

- 英文（默认）：[README.md](README.md)、[CHANGELOG.md](CHANGELOG.md)
- 简体中文：[README.zh-CN.md](README.zh-CN.md)、[CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)

## License

MIT（不含抖音表情素材版权）
