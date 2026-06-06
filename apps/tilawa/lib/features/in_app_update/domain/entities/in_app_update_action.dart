/// Domain decision for how an available update should be handled.
enum InAppUpdateAction {
  performImmediate,
  startFlexible,
  offerOptionalImmediate,
  none,
}
