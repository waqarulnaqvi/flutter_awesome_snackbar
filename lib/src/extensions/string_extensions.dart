import '../awesome_snackbar.dart';
import '../awesome_options.dart';

/// Convenience extensions on [String] for quickly flashing notifications.
extension AwesomeStringX on String {
  /// Show a success notification with this string as the message.
  String flashSuccess({String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.success(this, title: title, options: options);

  /// Show an error notification with this string as the message.
  String flashError({String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.error(this, title: title, options: options);

  /// Show a warning notification with this string as the message.
  String flashWarning({String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.warning(this, title: title, options: options);

  /// Show an info notification with this string as the message.
  String flashInfo({String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.info(this, title: title, options: options);
}
