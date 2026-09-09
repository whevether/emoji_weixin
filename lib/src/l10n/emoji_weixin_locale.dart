/// Supported UI languages (passed via [EmojiWeixinConfig.locale]).
enum EmojiWeixinLocale {
  /// China — Simplified Chinese
  zh,

  /// United States — English
  en,

  /// Vietnam
  vi,

  /// Indonesia
  id,

  /// Philippines — Filipino
  fil,

  /// Malaysia — Malay
  ms,

  /// India — Hindi
  hi;

  /// Parse a language / region code such as `zh`, `en-US`, `vi_VN`, `fil`.
  static EmojiWeixinLocale fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return EmojiWeixinLocale.zh;
    final normalized = code.trim().toLowerCase().replaceAll('_', '-');
    final primary = normalized.split('-').first;
    return switch (primary) {
      'zh' || 'cn' => EmojiWeixinLocale.zh,
      'en' || 'us' => EmojiWeixinLocale.en,
      'vi' => EmojiWeixinLocale.vi,
      'id' => EmojiWeixinLocale.id,
      'fil' || 'tl' || 'ph' => EmojiWeixinLocale.fil,
      'ms' || 'my' => EmojiWeixinLocale.ms,
      'hi' || 'in' => EmojiWeixinLocale.hi,
      _ => EmojiWeixinLocale.en,
    };
  }

  String get languageCode => name;
}
