import 'package:flutter/material.dart';

import '../awesome_snackbar.dart';
import '../awesome_options.dart';

/// Convenience extensions on [BuildContext] for quickly flashing notifications.
///
/// The context is accepted as a parameter for API symmetry with typical Flutter
/// patterns, but [AwesomeSnackbar] is context-independent — the context is not
/// used internally.
extension AwesomeContextX on BuildContext {
  /// Show a success notification.
  String flashSuccess(String message, {String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.success(message, title: title, options: options);

  /// Show an error notification.
  String flashError(String message, {String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.error(message, title: title, options: options);

  /// Show a warning notification.
  String flashWarning(String message, {String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.warning(message, title: title, options: options);

  /// Show an info notification.
  String flashInfo(String message, {String? title, AwesomeOptions? options}) =>
      AwesomeSnackbar.info(message, title: title, options: options);
}
