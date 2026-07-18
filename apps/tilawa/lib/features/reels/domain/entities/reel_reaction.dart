/// Islamic reaction types for a reel (local-only; no social graph).
enum ReelReaction {
  loved,
  allahummaTaqabbal,
  subhanAllah,
  mashaAllah,
}

extension ReelReactionX on ReelReaction {
  String get analyticsValue => name;
}
