import 'package:flutter/foundation.dart';

/// Feature availability helpers that avoid importing `dart:io` on web.
abstract final class PlatformCaps {
  /// Native WeChat camera UI (iOS/Android only).
  static bool get supportsWechatCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Capture/pick image then edit — available everywhere.
  /// Web/desktop use [FileType.image]; mobile prefers WeChat camera.
  static bool get supportsCameraCapture => true;
}
