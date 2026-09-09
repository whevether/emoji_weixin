import 'dart:convert';

import 'package:emoji_weixin/emoji_weixin.dart';
import 'package:flutter/services.dart';

/// Loads example app settings from [assets/config.json].
class AppConfig {
  const AppConfig({
    this.klipyApiKey = '',
    this.locale = EmojiWeixinLocale.zh,
  });

  final String klipyApiKey;
  final EmojiWeixinLocale locale;

  bool get hasKlipy => klipyApiKey.trim().isNotEmpty;

  static Future<AppConfig> load() async {
    for (final path in const [
      'assets/config.json',
      'assets/config.example.json',
    ]) {
      try {
        final raw = await rootBundle.loadString(path);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final key = (json['klipyApiKey'] as String?)?.trim() ??
            (json['giphyApiKey'] as String?)?.trim() ??
            '';
        final locale = EmojiWeixinLocale.fromCode(
          json['locale'] as String? ?? json['language'] as String?,
        );
        // Ignore placeholder text from the example file.
        if (key.isEmpty || key.contains('填入')) {
          return AppConfig(locale: locale);
        }
        return AppConfig(klipyApiKey: key, locale: locale);
      } catch (_) {
        // try next
      }
    }
    return const AppConfig();
  }
}
