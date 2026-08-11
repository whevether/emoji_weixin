/// Host-app configuration for [EmojiWeixinPanel].
class EmojiWeixinConfig {
  const EmojiWeixinConfig({
    this.giphyApiKey,
  });

  /// Giphy API key. When null/empty, the search tab is hidden.
  final String? giphyApiKey;

  bool get hasGiphy =>
      giphyApiKey != null && giphyApiKey!.trim().isNotEmpty;

  String? get resolvedGiphyApiKey =>
      hasGiphy ? giphyApiKey!.trim() : null;

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
