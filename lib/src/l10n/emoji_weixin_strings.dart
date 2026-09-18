import 'emoji_weixin_locale.dart';

/// UI copy for [EmojiWeixinLocale].
class EmojiWeixinStrings {
  const EmojiWeixinStrings._(this.locale);

  /// Locale these strings were resolved for.
  final EmojiWeixinLocale locale;

  /// Returns strings for [locale].
  static EmojiWeixinStrings of(EmojiWeixinLocale locale) =>
      EmojiWeixinStrings._(locale);

  /// Tooltip for the add menu button.
  String get addTooltip => _t(
        zh: '添加',
        en: 'Add',
        vi: 'Thêm',
        id: 'Tambah',
        fil: 'Idagdag',
        ms: 'Tambah',
        hi: 'जोड़ें',
      );

  /// Tooltip for the sticker manager button.
  String get manageTooltip => _t(
        zh: '管理',
        en: 'Manage',
        vi: 'Quản lý',
        id: 'Kelola',
        fil: 'Pamahalaan',
        ms: 'Urus',
        hi: 'प्रबंधित करें',
      );

  /// Menu label: add / edit image from gallery.
  String get addEditImage => _t(
        zh: '添加/编辑图片',
        en: 'Add / edit image',
        vi: 'Thêm / chỉnh ảnh',
        id: 'Tambah / edit gambar',
        fil: 'Magdagdag / i-edit ang larawan',
        ms: 'Tambah / edit imej',
        hi: 'चित्र जोड़ें / संपादित करें',
      );

  /// Menu label: capture a photo sticker (mobile).
  String get captureSticker => _t(
        zh: '拍自己的表情',
        en: 'Take a photo sticker',
        vi: 'Chụp sticker của bạn',
        id: 'Ambil foto stiker',
        fil: 'Kumuha ng photo sticker',
        ms: 'Ambil stiker foto',
        hi: 'फ़ोटो स्टिकर लें',
      );

  /// Snackbar after adding [n] stickers from gallery.
  String addedCount(int n) => _t(
        zh: '已添加 $n 个表情',
        en: 'Added $n sticker(s)',
        vi: 'Đã thêm $n sticker',
        id: 'Menambahkan $n stiker',
        fil: 'Nagdagdag ng $n sticker',
        ms: 'Ditambah $n stiker',
        hi: '$n स्टिकर जोड़े गए',
      );

  /// Snackbar after a successful camera capture save.
  String get savedCapture => _t(
        zh: '已保存拍照表情',
        en: 'Photo sticker saved',
        vi: 'Đã lưu sticker ảnh',
        id: 'Stiker foto disimpan',
        fil: 'Na-save ang photo sticker',
        ms: 'Stiker foto disimpan',
        hi: 'फ़ोटो स्टिकर सहेजा गया',
      );

  /// Generic operation failure message including [error].
  String operationFailed(Object error) => _t(
        zh: '操作失败: $error',
        en: 'Failed: $error',
        vi: 'Thất bại: $error',
        id: 'Gagal: $error',
        fil: 'Nabigo: $error',
        ms: 'Gagal: $error',
        hi: 'विफल: $error',
      );

  /// Panel load failure message including [error].
  String loadFailed(Object error) => _t(
        zh: '加载失败: $error',
        en: 'Load failed: $error',
        vi: 'Tải thất bại: $error',
        id: 'Gagal memuat: $error',
        fil: 'Hindi ma-load: $error',
        ms: 'Gagal dimuat: $error',
        hi: 'लोड विफल: $error',
      );

  /// Section title for recently used stickers.
  String get recentUsed => _t(
        zh: '最近使用',
        en: 'Recently used',
        vi: 'Dùng gần đây',
        id: 'Baru digunakan',
        fil: 'Kamakailang ginamit',
        ms: 'Baru digunakan',
        hi: 'हाल ही में उपयोग',
      );

  /// Section title for the full unicode emoji grid.
  String get allEmoji => _t(
        zh: '所有表情',
        en: 'All emoji',
        vi: 'Tất cả emoji',
        id: 'Semua emoji',
        fil: 'Lahat ng emoji',
        ms: 'Semua emoji',
        hi: 'सभी इमोजी',
      );

  /// Search tab label.
  String get search => _t(
        zh: '搜索',
        en: 'Search',
        vi: 'Tìm kiếm',
        id: 'Cari',
        fil: 'Maghanap',
        ms: 'Cari',
        hi: 'खोजें',
      );

  /// Default emoji pack tab label.
  String get emojiPack => _t(
        zh: '表情',
        en: 'Emoji',
        vi: 'Emoji',
        id: 'Emoji',
        fil: 'Emoji',
        ms: 'Emoji',
        hi: 'इमोजी',
      );

  /// Douyin sticker pack display name.
  String get douyinPack => _t(
        zh: '抖音表情',
        en: 'Douyin stickers',
        vi: 'Sticker Douyin',
        id: 'Stiker Douyin',
        fil: 'Mga sticker ng Douyin',
        ms: 'Stiker Douyin',
        hi: 'Douyin स्टिकर',
      );

  /// Sticker manager page title.
  String get manageTitle => _t(
        zh: '表情管理',
        en: 'Sticker manager',
        vi: 'Quản lý sticker',
        id: 'Kelola stiker',
        fil: 'Tagapamahala ng sticker',
        ms: 'Pengurus stiker',
        hi: 'स्टिकर प्रबंधक',
      );

  /// Rename action label.
  String get rename => _t(
        zh: '重命名',
        en: 'Rename',
        vi: 'Đổi tên',
        id: 'Ganti nama',
        fil: 'Palitan ang pangalan',
        ms: 'Namakan semula',
        hi: 'नाम बदलें',
      );

  /// Delete pack action label.
  String get deletePack => _t(
        zh: '删除表情包',
        en: 'Delete pack',
        vi: 'Xóa bộ sticker',
        id: 'Hapus paket',
        fil: 'Tanggalin ang pack',
        ms: 'Padam pek',
        hi: 'पैक हटाएँ',
      );

  /// Rename pack dialog title.
  String get renamePack => _t(
        zh: '重命名表情包',
        en: 'Rename pack',
        vi: 'Đổi tên bộ sticker',
        id: 'Ganti nama paket',
        fil: 'Palitan ang pangalan ng pack',
        ms: 'Namakan semula pek',
        hi: 'पैक का नाम बदलें',
      );

  /// Name text field hint.
  String get nameHint => _t(
        zh: '名称',
        en: 'Name',
        vi: 'Tên',
        id: 'Nama',
        fil: 'Pangalan',
        ms: 'Nama',
        hi: 'नाम',
      );

  /// Cancel button label.
  String get cancel => _t(
        zh: '取消',
        en: 'Cancel',
        vi: 'Hủy',
        id: 'Batal',
        fil: 'Cancel',
        ms: 'Batal',
        hi: 'रद्द करें',
      );

  /// Confirm / OK button label.
  String get confirm => _t(
        zh: '确定',
        en: 'OK',
        vi: 'OK',
        id: 'OK',
        fil: 'OK',
        ms: 'OK',
        hi: 'ठीक है',
      );

  /// Short count label for [n] stickers in a pack.
  String stickerCount(int n) => _t(
        zh: '$n 个',
        en: '$n items',
        vi: '$n mục',
        id: '$n item',
        fil: '$n item',
        ms: '$n item',
        hi: '$n आइटम',
      );

  /// Klipy search field hint.
  String get searchHint => _t(
        zh: '搜索 Klipy 表情',
        en: 'Search Klipy stickers',
        vi: 'Tìm sticker Klipy',
        id: 'Cari stiker Klipy',
        fil: 'Maghanap ng Klipy sticker',
        ms: 'Cari stiker Klipy',
        hi: 'Klipy स्टिकर खोजें',
      );

  /// Search filter: stickers.
  String get stickers => _t(
        zh: '贴纸',
        en: 'Stickers',
        vi: 'Sticker',
        id: 'Stiker',
        fil: 'Stickers',
        ms: 'Stiker',
        hi: 'स्टिकर',
      );

  /// Search filter: GIFs.
  String get gifs => _t(
        zh: 'GIF',
        en: 'GIF',
        vi: 'GIF',
        id: 'GIF',
        fil: 'GIF',
        ms: 'GIF',
        hi: 'GIF',
      );

  /// Klipy search failure message including [error].
  String searchFailed(Object error) => _t(
        zh: '搜索失败（请检查 Klipy API Key）\n$error',
        en: 'Search failed (check Klipy API key)\n$error',
        vi: 'Tìm kiếm thất bại (kiểm tra khóa API Klipy)\n$error',
        id: 'Pencarian gagal (periksa kunci API Klipy)\n$error',
        fil: 'Nabigo ang paghahanap (suriin ang Klipy API key)\n$error',
        ms: 'Carian gagal (semak kunci API Klipy)\n$error',
        hi: 'खोज विफल (Klipy API कुंजी जाँचें)\n$error',
      );

  /// Default name for a camera-captured sticker.
  String get photoStickerName => _t(
        zh: '拍照表情',
        en: 'Photo sticker',
        vi: 'Sticker ảnh',
        id: 'Stiker foto',
        fil: 'Photo sticker',
        ms: 'Stiker foto',
        hi: 'फ़ोटो स्टिकर',
      );

  /// Human-readable label for a sticker source name (`builtin`, `custom`, …).
  String sourceLabel(String sourceName) => switch (sourceName) {
        'builtin' => _t(
            zh: '内置',
            en: 'Built-in',
            vi: 'Có sẵn',
            id: 'Bawaan',
            fil: 'Built-in',
            ms: 'Binaan',
            hi: 'इनबिल्ट',
          ),
        'custom' => _t(
            zh: '自定义',
            en: 'Custom',
            vi: 'Tùy chỉnh',
            id: 'Kustom',
            fil: 'Custom',
            ms: 'Tersuai',
            hi: 'कस्टम',
          ),
        'imported' => _t(
            zh: '已导入',
            en: 'Imported',
            vi: 'Đã nhập',
            id: 'Diimpor',
            fil: 'Na-import',
            ms: 'Diimport',
            hi: 'आयातित',
          ),
        'klipy' => 'Klipy',
        _ => sourceName,
      };

  String _t({
    required String zh,
    required String en,
    required String vi,
    required String id,
    required String fil,
    required String ms,
    required String hi,
  }) {
    return switch (locale) {
      EmojiWeixinLocale.zh => zh,
      EmojiWeixinLocale.en => en,
      EmojiWeixinLocale.vi => vi,
      EmojiWeixinLocale.id => id,
      EmojiWeixinLocale.fil => fil,
      EmojiWeixinLocale.ms => ms,
      EmojiWeixinLocale.hi => hi,
    };
  }
}
