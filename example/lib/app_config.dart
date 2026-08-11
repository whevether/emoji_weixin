import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads example app settings from [assets/config.json].
class AppConfig {
  const AppConfig({this.klipyApiKey = ''});

  final String klipyApiKey;

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
        // Ignore placeholder text from the example file.
        if (key.isEmpty || key.contains('填入')) {
          continue;
        }
        return AppConfig(klipyApiKey: key);
      } catch (_) {
        // try next
      }
    }
    return const AppConfig();
  }
}
