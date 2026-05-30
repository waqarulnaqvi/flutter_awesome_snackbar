import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'awesome_config.dart';
import 'awesome_history.dart';
import 'awesome_options.dart';
import 'enums/awesome_haptic.dart';
import 'enums/awesome_priority.dart';
import 'enums/awesome_type.dart';

/// Entry point for every notification. Zero setup beyond [AwesomeWidget.init].
///
/// ```dart
/// AwesomeSnackbar.success("Saved!");
/// AwesomeSnackbar.error("Payment failed.");
/// ```
abstract final class AwesomeSnackbar {
  AwesomeSnackbar._();

  static AwesomeConfig _config = const AwesomeConfig();
  static final _queue = <_QueueEntry>[];
  static final _active = <String, _ActiveEntry>{};
  static final _keys = <String>{};
  static final _scheduledTimers = <String, Timer>{};

  // ─── Configuration ───────────────────────────────────────────────────────

  /// Apply global defaults. Call once, typically at app startup.
  ///
  /// ```dart
  /// AwesomeSnackbar.configure(AwesomeConfig(
  ///   position: AwesomePosition.bottom,
  ///   blur: true,
  ///   defaultHaptic: AwesomeHaptic.light,
  /// ));
  /// ```
  static void configure(AwesomeConfig config) => _config = config;

  /// Current global config.
  static AwesomeConfig get config => _config;

  // ─── Navigator key ───────────────────────────────────────────────────────

  /// Attach to [MaterialApp.navigatorKey] if you use [AwesomeOptions.routeName].
  static final navigatorKey = GlobalKey<NavigatorState>();

  // ─── Convenience shortcuts ───────────────────────────────────────────────

  /// Show a success notification.
  static String success(
      String message, {
        String? title,
        AwesomeOptions? options,
      }) =>
      show(
        _merge(options,
            type: AwesomeType.success, message: message, title: title),
      );

  /// Show an error notification.
  static String error(
      String message, {
        String? title,
        AwesomeOptions? options,
      }) =>
      show(
        _merge(options,
            type: AwesomeType.error, message: message, title: title),
      );

  /// Show a warning notification.
  static String warning(
      String message, {
        String? title,
        AwesomeOptions? options,
      }) =>
      show(
        _merge(options,
            type: AwesomeType.warning, message: message, title: title),
      );

  /// Show an info notification.
  static String info(
      String message, {
        String? title,
        AwesomeOptions? options,
      }) =>
      show(
        _merge(options, type: AwesomeType.info, message: message, title: title),
      );

  /// Show a persistent loading notification; returns its [id].
  ///
  /// Dismiss manually with [dismissById].
  static String loading(String message) => show(
    AwesomeOptions(
      type: AwesomeType.loading,
      message: message,
      persistent: true,
    ),
  );

  // ─── Full control ────────────────────────────────────────────────────────

  /// Show a notification with full [AwesomeOptions] control.
  ///
  /// Returns the notification's unique ID (useful for [dismissById]).
  static String show(AwesomeOptions options) {
    final id = _generateId();

    // Duplicate prevention
    final dedupeKey = options.key;
    if (dedupeKey != null && _keys.contains(dedupeKey)) return '';
    if (dedupeKey != null) _keys.add(dedupeKey);

    final entry = _QueueEntry(id: id, options: options);

    // Priority insertion
    switch (options.priority) {
      case AwesomePriority.critical:
        _queue.insert(0, entry);
      case AwesomePriority.high:
        final normalIdx = _queue
            .indexWhere((e) => e.options.priority == AwesomePriority.normal);
        _queue.insert(normalIdx == -1 ? _queue.length : normalIdx, entry);
      case AwesomePriority.normal:
        _queue.add(entry);
    }

    // History
    if (_config.enableHistory) {
      AwesomeHistory.instance.add(
        AwesomeRecord(id: id, options: options, shownAt: DateTime.now()),
      );
    }

    _triggerHaptic(options.haptic ?? _config.defaultHaptic);
    _processQueue();
    return id;
  }

  /// Await a [Future] and show loading / success / error notifications automatically.
  ///
  /// ```dart
  /// await AwesomeSnackbar.future(
  ///   future: uploadFile(),
  ///   loading: "Uploading...",
  ///   success: "Done! 🎉",
  ///   error: "Upload failed.",
  /// );
  /// ```
  static Future<T?> future<T>({
    required Future<T> future,
    required String loading,
    required Object success,
    required Object error,
    AwesomeOptions? loadingOptions,
    AwesomeOptions? successOptions,
    AwesomeOptions? errorOptions,
  }) async {
    final loadId = show(
      _merge(
        loadingOptions,
        type: AwesomeType.loading,
        message: loading,
        persistent: true,
      ),
    );
    try {
      final result = await future;
      dismissById(loadId);
      final msg = success is String Function(T)
          ? (success)(result)
          : success.toString();
      show(_merge(successOptions, type: AwesomeType.success, message: msg));
      return result;
    } catch (e) {
      dismissById(loadId);
      final msg = error is String Function(Object)
          ? (error)(e)
          : error.toString();
      show(_merge(errorOptions, type: AwesomeType.error, message: msg));
      return null;
    }
  }

  // ─── Scheduling ──────────────────────────────────────────────────────────

  /// Show a notification after [delay].
  ///
  /// Returns a schedule ID; cancel with [cancelScheduled].
  static String schedule({
    required Duration delay,
    required AwesomeOptions options,
  }) {
    final sid = _generateId();
    _scheduledTimers[sid] = Timer(delay, () {
      _scheduledTimers.remove(sid);
      show(options);
    });
    return sid;
  }

  /// Cancel a previously scheduled notification.
  static void cancelScheduled(String scheduleId) {
    _scheduledTimers[scheduleId]?.cancel();
    _scheduledTimers.remove(scheduleId);
  }

  // ─── Dismissal ───────────────────────────────────────────────────────────

  /// Dismiss a specific notification by [id].
  static void dismissById(String id) {
    _active[id]?.dismiss();
    _active.remove(id);
    _keys.removeWhere((k) {
      // remove dedupe key associated with this id if any
      return false; // key tracking is per-options.key, not per-id; leave as-is
    });
    _processQueue();
    if (_config.enableHistory) AwesomeHistory.instance.markDismissed(id);
  }

  /// Dismiss all visible notifications immediately.
  static void dismissAll() {
    for (final entry in _active.values) {
      entry.dismiss();
    }
    _active.clear();
    _queue.clear();
    _keys.clear();
  }

  /// Dismiss all notifications belonging to [groupKey].
  static void dismissGroup(String groupKey) {
    final ids = _active.entries
        .where((e) => e.value.options.groupKey == groupKey)
        .map((e) => e.key)
        .toList();
    for (final id in ids) {
      dismissById(id);
    }
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  static void _processQueue() {
    final maxV = _config.maxVisible;
    while (_active.length < maxV && _queue.isNotEmpty) {
      final entry = _queue.removeAt(0);
      // Register as active with a no-op dismiss — the real dismiss comes from
      // the widget via [registerActive] / [unregisterActive].
      AwesomeSnackbar._active[entry.id] =
          _ActiveEntry(id: entry.id, options: entry.options, dismiss: () {});
      AwesomeController._instance._emit(
        AwesomeShowEvent(id: entry.id, options: entry.options),
      );
    }
  }

  /// Called by the widget to register its dismiss callback.
  static void registerActive(String id, VoidCallback dismiss) {
    final existing = _active[id];
    if (existing != null) {
      _active[id] =
          _ActiveEntry(id: existing.id, options: existing.options, dismiss: dismiss);
    }
  }

  /// Called by the widget when a notification finishes its exit animation.
  static void unregisterActive(String id) {
    _active.remove(id);
    // Also remove dedupe key so the same key can be shown again later.
    final key = _active[id]?.options.key;
    if (key != null) _keys.remove(key);
    _processQueue();
  }

  static String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

  static Future<void> _triggerHaptic(AwesomeHaptic haptic) async {
    switch (haptic) {
      case AwesomeHaptic.none:
        break;
      case AwesomeHaptic.light:
        await HapticFeedback.lightImpact();
      case AwesomeHaptic.medium:
        await HapticFeedback.mediumImpact();
      case AwesomeHaptic.heavy:
      case AwesomeHaptic.vibrate:
        await HapticFeedback.heavyImpact();
      case AwesomeHaptic.success:
        await HapticFeedback.selectionClick();
      case AwesomeHaptic.warning:
        await HapticFeedback.mediumImpact();
      case AwesomeHaptic.error:
        await HapticFeedback.heavyImpact();
    }
  }

  static AwesomeOptions _merge(
      AwesomeOptions? base, {
        required AwesomeType type,
        String? message,
        String? title,
        bool? persistent,
      }) {
    return AwesomeOptions(
      title: title ?? base?.title,
      message: message ?? base?.message,
      type: type,
      position: base?.position,
      animation: base?.animation,
      animationBuilder: base?.animationBuilder,
      pathAnimation: base?.pathAnimation,
      duration: base?.duration ?? const Duration(seconds: 4),
      actionText: base?.actionText,
      onAction: base?.onAction,
      secondaryActionText: base?.secondaryActionText,
      onSecondaryAction: base?.onSecondaryAction,
      showProgress: base?.showProgress ?? false,
      dismissDirection: base?.dismissDirection,
      priority: base?.priority ?? AwesomePriority.normal,
      key: base?.key,
      iconWidget: base?.iconWidget,
      iconAsset: base?.iconAsset,
      iconNetwork: base?.iconNetwork,
      iconProvider: base?.iconProvider,
      customWidget: base?.customWidget,
      themeData: base?.themeData,
      haptic: base?.haptic,
      onTap: base?.onTap,
      onDismiss: base?.onDismiss,
      routeName: base?.routeName,
      groupKey: base?.groupKey,
      dismissOnTap: base?.dismissOnTap ?? false,
      persistent: persistent ?? base?.persistent ?? false,
      tag: base?.tag,
      maxWidth: base?.maxWidth,
      borderRadius: base?.borderRadius,
      margin: base?.margin,
      padding: base?.padding,
      showTimestamp: base?.showTimestamp ?? false,
      accessibilityLabel: base?.accessibilityLabel,
    );
  }
}

// ─── Internal data structures ────────────────────────────────────────────────

class _QueueEntry {
  const _QueueEntry({required this.id, required this.options});
  final String id;
  final AwesomeOptions options;
}

class _ActiveEntry {
  const _ActiveEntry({
    required this.id,
    required this.options,
    required this.dismiss,
  });
  final String id;
  final AwesomeOptions options;
  final VoidCallback dismiss;
}

// ─── Shared stream bridge (single source of truth) ───────────────────────────

/// Event emitted when a notification should be displayed.
class AwesomeShowEvent {
  const AwesomeShowEvent({required this.id, required this.options});
  final String id;
  final AwesomeOptions options;
}

/// Singleton stream controller shared between [AwesomeSnackbar] and
/// [AwesomeWidget]. This fixes the previous split-definition bug where
/// `emit()` lived in one file and `stream` lived in the other, meaning
/// notifications were enqueued but never rendered.
class AwesomeController {
  AwesomeController._();
  static final AwesomeController _instance = AwesomeController._();

  final StreamController<AwesomeShowEvent> _ctrl =
  StreamController<AwesomeShowEvent>.broadcast();

  Stream<AwesomeShowEvent> get stream => _ctrl.stream;

  void _emit(AwesomeShowEvent event) => _ctrl.add(event);

  /// Exposed so [AwesomeWidget] can subscribe.
  static Stream<AwesomeShowEvent> get events => _instance.stream;
}