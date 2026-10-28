
/// Bottom nav bar "press and slide": converts the pointer's x coordinate into the Tab index that should be selected.
///
/// The bar is treated as [tabCount] equal segments; the pointer selects whichever segment it lands in.
/// Used for the custom bottom bar when liquid glass is disabled (when enabled, the official
/// GlassTabBar.bottom takes over, whose implementation also includes a magic-lens indicator and jelly physics animation).
int barTabFromX(double dx, double barWidth, int tabCount) {
  if (barWidth <= 0 || tabCount <= 1) return 0;
  final idx = (dx / (barWidth / tabCount)).floor();
  return idx.clamp(0, tabCount - 1);
}
