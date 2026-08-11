# emoji_weixin

[English](README.md) | [简体中文](README.zh-CN.md)

仿微信风格的 Flutter 表情/贴纸面板 Package。

功能：

1. **Klipy 在线搜索**并下载合成为本地收藏表情  
2. **常规表情**（Unicode 表情 +「最近使用」、抖音常用表情）  
3. **自定义表情**管理（`file_picker` 选择图片/GIF/Lottie）  
4. **拍自己的表情**（iOS/Android：`wechat_camera_picker`；Web/桌面：`file_picker` `FileType.image` → `pro_image_editor`）  
5. **导入表情包**（zip / 单文件，支持 PNG、JPG、WebP、GIF、Lottie）

## 平台支持

| 能力 | iOS | Android | Web | macOS | Windows | Linux |
|------|-----|---------|-----|-------|---------|-------|
| 表情面板 / 最近使用 / 抖音表情 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| file_picker 添加/导入 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| Klipy 搜索合成 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| 拍照/选图编辑 | WeChat 相机 | WeChat 相机 | FileType.image | FileType.image | FileType.image | FileType.image |

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
  const EmojiWeixinConfig(klipyApiKey: '你的 Klipy API Key'),
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

## 导入表情包格式

zip 内建议包含 `manifest.json`：

```json
{
  "name": "演示表情包",
  "id": "sample_demo",
  "stickers": [
    {"file": "smile.png", "name": "微笑"},
    {"file": "spark.json", "name": "闪光", "kind": "lottie"}
  ]
}
```

example 自带样例：`example/assets/sample_pack.zip`。

## Android 配置（example）

对齐 [kinetic_player/example](https://github.com/wanwenfeng4798/kinetic_player/tree/main/example)：

- `compileSdk` / `targetSdk`：**37**
- `minSdk`：24
- AGP：**9.3.1**
- Kotlin：**2.4.10**
- Gradle：**9.6.1**
- `file_picker`：**12.0.0-beta.7**（兼容 AGP 9）
- Release 签名：[`example/android/key.properties`](example/android/key.properties) + [`example/jks/emoji_weixin.jks`](example/jks/emoji_weixin.jks)（演示用证书，生产请自行替换）
- Release 开启混淆压缩 + [`proguard-rules.pro`](example/android/app/proguard-rules.pro)

## 平台权限

### iOS

- `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` / `NSPhotoLibraryUsageDescription`

### Android

- `CAMERA` / `INTERNET` / `READ_MEDIA_IMAGES`

### macOS

- App Sandbox + `network.client` + `files.user-selected.read-write`

## 主要 API

| API | 说明 |
|-----|------|
| `EmojiWeixinConfig` | 应用/面板配置（如 Klipy Key） |
| `EmojiWeixinPanel` | 仿微信底部表情面板 |
| `StickerRepository` | 表情包/收藏持久化（Hive） |
| `StickerImportService` | `file_picker` 添加与导入 |
| `CameraStickerService` | 拍照/选图 + 编辑 |
| `KlipyClient` / `KlipyStickerService` | 搜索与下载合成 |
| `StickerRenderer` | PNG/GIF/Lottie/Unicode 统一渲染 |

## 文档

- 英文（默认）：[README.md](README.md)、[CHANGELOG.md](CHANGELOG.md)
- 简体中文：[README.zh-CN.md](README.zh-CN.md)、[CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)

## License

MIT（不含抖音表情素材版权）
