/// Haptic feedback style triggered when a notification appears.
///
/// Implemented with Flutter's built-in [HapticFeedback] — no external package needed.
enum AwesomeHaptic {
  /// No haptic feedback.
  none,

  /// Light impact.
  light,

  /// Medium impact.
  medium,

  /// Heavy impact.
  heavy,

  /// Success notification feedback (selectionClick pattern).
  success,

  /// Warning notification feedback (medium impact).
  warning,

  /// Error notification feedback (heavy impact).
  error,

  /// Short vibration pulse (heavy impact).
  vibrate,
}
