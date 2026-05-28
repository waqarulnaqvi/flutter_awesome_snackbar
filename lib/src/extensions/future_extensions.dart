import '../awesome_options.dart';
import '../awesome_snackbar.dart';

/// Convenience extensions on [Future].
///
/// ```dart
/// uploadFile().flashFuture(
///   loading: "Uploading...",
///   success: (_) => "Done!",
///   error: (e) => "Failed: $e",
/// );
/// ```
extension AwesomeFutureExtensions<T> on Future<T> {
  /// Wraps this future with automatic loading / success / error notifications.
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
