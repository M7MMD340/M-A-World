/// Illustrated couple stickers, drawn to match the app's own characters.
/// Each key maps to `assets/images/stickers/$key.png`; a message with
/// [stickerKey] set to one of these renders that image instead of text.
const stickerCatalog = <String, String>{
  'hug': 'عناق',
  'laugh': 'ضحك',
  'wow': 'تفاجؤ',
  'miss': 'اشتياق',
  'yes': 'إعجاب',
  'love': 'حب',
  'angry': 'زعل',
  'yummy': 'يمي',
  'sleepy': 'نعسان',
  'party': 'احتفال',
  'shy': 'خجل',
  'hi': 'هلا',
};

String stickerAssetPath(String key) => 'assets/images/stickers/$key.png';
