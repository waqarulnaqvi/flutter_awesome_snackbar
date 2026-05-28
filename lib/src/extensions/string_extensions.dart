import '../awesome_snackbar.dart';

/// Convenience extensions on [String].
///
/// ```dart
/// "Saved!".flashSuccess();
/// "Payment failed.".flashError(title: "Oops");
/// ```
extension AwesomeStringExtensions on String {
  /// Show as a success notification.
  String flashSuccess({String? title}) =>
      AwesomeSnackbar.success(this, title: title);

  /// Show as an error notification.
  String flashError({String? title}) =>
      AwesomeSnackbar.error(this, title: title);

  /// Show as a warning notification.
  String flashWarning({String? title}) =>
      AwesomeSnackbar.warning(this, title: title);

  /// Show as an info notification.
  String flashInfo({String? title}) =>
      AwesomeSnackbar.info(this, title: title);
}
