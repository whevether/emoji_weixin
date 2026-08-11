import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads example app settings from [assets/config.json].
class AppConfig {
  const AppConfig({this.giphyApiKey = ''});

  final String giphyApiKey;

  bool get hasGiphy => giphyApiKey.trim().isNotEmpty;

  static Future<AppConfig> load() async {
    for (final path in const [
      'assets/config.json',
      'assets/config.example.json',
    ]) {
      try {
        final raw = await rootBundle.loadString(path);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final key = (json['giphyApiKey'] as String?)?.trim() ?? '';
        // Ignore placeholder text from the example file.
        if (key.isEmpty || key.contains('填入')) {
          continue;
        }
        return AppConfig(giphyApiKey: key);
      } catch (_) {
        // try next
      }
    }
    return const AppConfig();
  }
}
