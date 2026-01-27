import 'constants.dart';

/// Filters objectionable content in user-generated text.
/// Returns true if text contains banned words/phrases.
bool containsBannedContent(String? text) {
  if (text == null || text.isEmpty) return false;
  final lower = text.toLowerCase().trim();
  for (final word in AppConstants.bannedWords) {
    if (lower.contains(word.toLowerCase())) return true;
  }
  return false;
}

/// Returns a user-friendly message when content is rejected.
String getBannedContentMessage() =>
    'Nội dung chứa từ ngữ không phù hợp. Vui lòng chỉnh sửa theo Quy định cộng đồng.';
