import '../awesome_snackbar.dart';
import '../awesome_options.dart';

/// Convenience extensions on [Future] for tracking async operations.
extension AwesomeFutureX<T> on Future<T> {
  /// Track this [Future] with loading / success / error notifications.
  ///
  /// Shows a persistent loading notification until the future resolves,
  /// then replaces it with a success or error notification.
  ///
  /// [loading] — message shown while the future is pending.
  /// [success] — either a plain [String] or a `String Function(T)` callback
  ///             that receives the resolved value.
  /// [error]   — either a plain [String] or a `String Function(Object)` callback
  ///             that receives the thrown error.
  Future<T?> flashFuture({
    required String loading,
    required Object success,
    required Object error,
    AwesomeOptions? loadingOptions,
    AwesomeOptions? successOptions,
    AwesomeOptions? errorOptions,
  }) =>
      AwesomeSnackbar.future<T>(
        future: this,
        loading: loading,
        success: success,
        error: error,
        loadingOptions: loadingOptions,
        successOptions: successOptions,
        errorOptions: errorOptions,
      );
}
