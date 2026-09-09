import '../l10n/emoji_weixin_locale.dart';
import '../l10n/emoji_weixin_strings.dart';

/// Host-app configuration for [EmojiWeixinPanel].
class EmojiWeixinConfig {
  const EmojiWeixinConfig({
    this.klipyApiKey,
    this.locale = EmojiWeixinLocale.zh,
  });

  /// Klipy API key. When null/empty, the search tab is hidden.
  final String? klipyApiKey;

  /// UI language. Supported: zh / en / vi / id / fil / ms / hi
  /// (China / USA / Vietnam / Indonesia / Philippines / Malaysia / India).
  final EmojiWeixinLocale locale;

  EmojiWeixinStrings get strings => EmojiWeixinStrings.of(locale);

  bool get hasKlipy =>
      klipyApiKey != null && klipyApiKey!.trim().isNotEmpty;

  String? get resolvedKlipyApiKey =>
      hasKlipy ? klipyApiKey!.trim() : null;

  /// Optional process-wide default, set once at app startup.
  static EmojiWeixinConfig? _global;

  static EmojiWeixinConfig? get global => _global;

  /// Configure a global default used when a panel does not pass [config].
  static void configure(EmojiWeixinConfig config) {
    _global = config;
  }

  static void clearGlobal() {
    _global = null;
  }

  /// Use explicit [config], else the global default, else empty defaults.
  static EmojiWeixinConfig resolve(EmojiWeixinConfig? config) {
    return config ?? _global ?? const EmojiWeixinConfig();
  }
}
