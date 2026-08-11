/// Host-app configuration for [EmojiWeixinPanel].
class EmojiWeixinConfig {
  const EmojiWeixinConfig({
    this.klipyApiKey,
  });

  /// Klipy API key. When null/empty, the search tab is hidden.
  final String? klipyApiKey;

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

  /// Merge explicit [config] over the global default.
  static EmojiWeixinConfig resolve(EmojiWeixinConfig? config) {
    return config ?? _global ?? const EmojiWeixinConfig();
  }
}
