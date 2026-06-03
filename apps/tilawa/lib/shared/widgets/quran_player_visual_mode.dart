/// Visual mode labels for Quran player presentation snapshots.
String quranPlayerVisualMode({
  required double expandProgress,
  required bool isCollapsing,
  required bool isUserDragging,
  String? transitionOwner,
}) {
  if (expandProgress <= 0.01) {
    return transitionOwner == 'heroRouteClosing' ? 'miniClosing' : 'mini';
  }
  if (expandProgress >= 0.99) {
    return transitionOwner == 'heroRoute' ? 'expandedOpening' : 'expanded';
  }
  if (isCollapsing) {
    return 'collapsing';
  }
  if (isUserDragging) {
    return 'dragging';
  }
  return 'transition';
}
