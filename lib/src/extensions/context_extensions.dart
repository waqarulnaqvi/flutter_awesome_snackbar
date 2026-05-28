import 'package:flutter/material.dart';

import '../awesome_options.dart';
import '../awesome_snackbar.dart';

/// Convenience extensions on [BuildContext].
extension AwesomeContextExtensions on BuildContext {
  /// Show a success notification.
  String flashSuccess(String message, {String? title}) =>
      AwesomeSnackbar.success(message, title: title);

  /// Show an error notification.
  String flashError(String message, {String? title}) =>
      AwesomeSnackbar.error(message, title: title);

  /// Show a warning notification.
  String flashWarning(String message, {String? title}) =>
      AwesomeSnackbar.warning(message, title: title);

  /// Show an info notification.
  String flashInfo(String message, {String? title}) =>
      AwesomeSnackbar.info(message, title: title);

  /// Show a notification with full [AwesomeOptions] control.
  String flashShow(AwesomeOptions options) => AwesomeSnackbar.show(options);

  /// Dismiss all visible notifications.
  void flashDismissAll() => AwesomeSnackbar.dismissAll();
}
