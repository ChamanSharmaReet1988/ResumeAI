/// Shared layout for modal bottom sheets across the app.
abstract final class BottomSheetInsets {
  /// Extra space below the sheet’s top edge (drag handle area on Material 3).
  static const double topSpacing = 10;

  /// Extra inset from the leading edge for sheet content (Material list tiles are
  /// often flush; this adds breathing room on the left).
  static const double leftPadding = 12;
}
