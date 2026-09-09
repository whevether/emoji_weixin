import 'package:flutter/foundation.dart';

/// Feature availability helpers that avoid importing `dart:io` on web.
abstract final class PlatformCaps {
  /// Native camera via [image_picker] (iOS/Android only).
  static bool get supportsMobileCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }
}
