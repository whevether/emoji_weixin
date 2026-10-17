# emoji_weixin example

[English](README.md) | [简体中文](README.zh-CN.md)

`emoji_weixin` 的演示聊天应用。

## 演示视频

本示例录屏（搜索 → 发送 → 右键收藏）：

<video src="demo/emoji_weixin_demo.mp4" controls width="720"></video>

- [`demo/emoji_weixin_demo.mp4`](demo/emoji_weixin_demo.mp4)

## 运行

```bash
# 在本目录下
# 如需 Klipy 搜索，编辑 assets/config.local.json 填入 klipyApiKey
flutter pub get
flutter run --dart-define-from-file=assets/config.local.json  # 或 -d chrome / macos / windows / linux
```

## 配置

- `assets/config.local.json` — 本地配置（`klipyApiKey`）
- [`assets/config.example.json`](assets/config.example.json) — 示例模板

包文档：[../README.md](../README.md) · 中文：[../README.zh-CN.md](../README.zh-CN.md)

本地配置：复制 `assets/config.example.json` 为 `assets/config.local.json`，填入 Key 后运行 `flutter run --dart-define-from-file=assets/config.local.json`。本地文件不打包为资源且不提交 Git；编译进客户端的 Key 仍可从产物中提取。历史上提交过的 Key 应在 KLIPY 控制台轮换。
