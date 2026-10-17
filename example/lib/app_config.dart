import 'dart:convert';

import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Public example defaults, overridden by --dart-define-from-file.
class AppConfig {
  /// Creates example settings without requiring a network API key.
  const AppConfig({this.klipyApiKey = '', this.locale = EmojiWeixinLocale.zh});

  /// Optional public client key; build-time values are still visible in binaries.
  final String klipyApiKey;

  /// Preferred UI language.
  final EmojiWeixinLocale locale;

  /// Reads public defaults and optional build-time local settings.
  static Future<AppConfig> load() async {
    Map<String, dynamic> defaults = const {};
    try {
      defaults = jsonDecode(
        await rootBundle.loadString('assets/config.example.json'),
      ) as Map<String, dynamic>;
    } on FlutterError {
      // The demo also runs when its optional defaults asset isn't bundled.
    }
    const key = String.fromEnvironment(
      'klipyApiKey',
      defaultValue: String.fromEnvironment('KLIPY_API_KEY'),
    );
    const locale = String.fromEnvironment('locale');
    return AppConfig(
      klipyApiKey: key.trim(),
      locale: EmojiWeixinLocale.fromCode(
        locale.isEmpty ? defaults['locale'] as String? : locale,
      ),
    );
  }
}
