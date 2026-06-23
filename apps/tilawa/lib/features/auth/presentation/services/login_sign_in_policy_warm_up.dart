/// Runs sign-in policy warm-up when [isPolicyRegistered], otherwise no-op.
Future<void> warmUpLoginSignInPolicy({
  required bool isPolicyRegistered,
  required Future<void> Function() warmUp,
}) {
  if (!isPolicyRegistered) {
    return Future<void>.value();
  }
  return warmUp();
}
