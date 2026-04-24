/// A base exception for errors in the quran package.
class QuranException implements Exception {
  const QuranException(this.message);
  final String message;

  @override
  String toString() => 'QuranException: $message';
}
