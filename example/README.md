# emoji_weixin example

[English](README.md) | [简体中文](README.zh-CN.md)

Demo chat app for the `emoji_weixin` package.

## Demo video

Screen recording of this example (search → send → right-click favorite):

<video src="demo/emoji_weixin_demo.mp4" controls width="720"></video>

- [`demo/emoji_weixin_demo.mp4`](demo/emoji_weixin_demo.mp4)

## Run

```bash
# From this directory
# Edit assets/config.local.json and set klipyApiKey if you need Klipy search
flutter pub get
flutter run --dart-define-from-file=assets/config.local.json  # or -d chrome / macos / windows / linux
```

## Config

- `assets/config.local.json` — local settings (`klipyApiKey`)
- [`assets/config.example.json`](assets/config.example.json) — sample template

Package docs: [../README.md](../README.md) · Chinese: [../README.zh-CN.md](../README.zh-CN.md)

Copy `assets/config.example.json` to ignored `assets/config.local.json`, then run `flutter run --dart-define-from-file=assets/config.local.json`. Local settings are not bundled as assets. Build-time client keys are still extractable from binaries; rotate previously committed keys in the KLIPY console.
