class AppConstants {
  // Support & Legal URLs (must be valid for App Store)
  static const String supportUrl = 'https://sites.google.com/view/tangdo/home';
  static const String termsUrl = 'https://sites.google.com/view/tangdo/terms';

  // Banned words for content filtering (objectionable content)
  static const List<String> bannedWords = [
    // Add words to filter - keep minimal, expand as needed
    'lừa đảo', 'scam', 'spam',
  ];

  // Product Categories
  static const List<String> categories = [
    'Đồ điện tử',
    'Thực phẩm',
    'Mỹ phẩm',
    'Quần áo',
    'Sách',
    'Thú cưng',
    'Đồ chơi',
    'Văn phòng phẩm',
    'Đồ gia dụng',
    'Khác',
  ];

  // Product Conditions
  static const String conditionNew = 'new';
  static const String conditionUsed = 'used';

  // Default Expiry Days
  static const int defaultExpiryDays = 30;
}

