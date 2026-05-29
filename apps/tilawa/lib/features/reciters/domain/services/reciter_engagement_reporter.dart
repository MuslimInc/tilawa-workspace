/// Reports reciter engagement signals without coupling reciters data to other features.
abstract interface class ReciterEngagementReporter {
  /// Called when the user adds a reciter to favorites.
  void reportFavoriteReciterAdded();
}
