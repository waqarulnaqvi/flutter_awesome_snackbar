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

  /// All pending notifications waiting to be shown, in priority order.
  static final _queue = <_QueueEntry>[];

  /// All active entries keyed by id.
  static final _activeEntries = <String, _ActiveEntry>{};

  /// True while the current notification is still playing its exit animation.
  static bool _isExiting = false;

  /// Tracks which dedupe keys are in-flight (active or queued).
  static final _keyToId = <String, String>{};

  static final _scheduledTimers = <String, Timer>{};

  // ─── Configuration ───────────────────────────────────────────────────────

  /// Apply global defaults. Call once, typically at app startup.
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
      show(_merge(options,
          type: AwesomeType.success, message: message, title: title));

  /// Show an error notification.
  static String error(
    String message, {
    String? title,
    AwesomeOptions? options,
  }) =>
      show(_merge(options,
          type: AwesomeType.error, message: message, title: title));

  /// Show a warning notification.
  static String warning(
    String message, {
    String? title,
    AwesomeOptions? options,
  }) =>
      show(_merge(options,
          type: AwesomeType.warning, message: message, title: title));

  /// Show an info notification.
  static String info(
    String message, {
    String? title,
    AwesomeOptions? options,
  }) =>
      show(_merge(options,
          type: AwesomeType.info, message: message, title: title));

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

    // Duplicate prevention — same key already active or queued → skip.
    final dedupeKey = options.key;
    if (dedupeKey != null && _keyToId.containsKey(dedupeKey)) return '';
    if (dedupeKey != null) _keyToId[dedupeKey] = id;

    // History record (queued notifications are recorded immediately).
    if (_config.enableHistory) {
      AwesomeHistory.instance.add(
        AwesomeRecord(id: id, options: options, shownAt: DateTime.now()),
      );
    }

    _triggerHaptic(options.haptic ?? _config.defaultHaptic);

    // Priority insertion into queue.
    final entry = _QueueEntry(id: id, options: options);
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

    _processQueue();
    return id;
  }

  /// Await a [Future] and show loading / success / error notifications automatically.
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
      _merge(loadingOptions,
          type: AwesomeType.loading, message: loading, persistent: true),
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

  /// Show a notification after [delay]. Returns a schedule ID.
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

  /// Dismiss the currently visible notification by [id].
  static void dismissById(String id) {
    final active = _activeEntries[id];
    if (active != null) {
      active.dismiss();
    } else {
      // It may still be in the queue — remove it there.
      _queue.removeWhere((e) => e.id == id);
      _keyToId.removeWhere((k, v) => v == id);
    }
  }

  /// Dismiss all visible notifications and clear the entire queue.
  static void dismissAll() {
    _queue.clear();
    for (final entry in List.of(_activeEntries.values)) {
      entry.dismiss();
    }
  }

  /// Dismiss all notifications belonging to [groupKey].
  static void dismissGroup(String groupKey) {
    _queue.removeWhere((e) => e.options.groupKey == groupKey);
    for (final entry in List.of(_activeEntries.values)) {
      if (entry.options.groupKey == groupKey) {
        entry.dismiss();
      }
    }
  }

  // ─── Internal API ────────────────────────────────────────────────────────

  /// Promote the next queued item to active when no non-exiting entry is on
  /// screen and nothing is in the middle of its exit animation.
  static void _processQueue() {
    final visibleCount =
        _activeEntries.values.where((e) => !e.isExiting).length;
    if (visibleCount >= 1) return; // sequential mode: one at a time
    if (_isExiting) return;
    if (_queue.isEmpty) return;

    final entry = _queue.removeAt(0);

    // Register with a no-op dismiss first; real callback comes via registerActive().
    _activeEntries[entry.id] = _ActiveEntry(
      id: entry.id,
      options: entry.options,
      dismiss: () {},
      isExiting: false,
    );

    AwesomeController._instance._emit(
      AwesomeShowEvent(id: entry.id, options: entry.options),
    );
  }

  /// Called by the widget to register its dismiss callback once it mounts.
  static void registerActive(String id, VoidCallback dismiss) {
    final existing = _activeEntries[id];
    if (existing != null) {
      _activeEntries[id] = _ActiveEntry(
        id: existing.id,
        options: existing.options,
        dismiss: dismiss,
        isExiting: existing.isExiting,
      );
    }
  }

  /// Called by the widget AFTER the exit animation fully completes.
  static void unregisterActive(String id) {
    final entry = _activeEntries.remove(id);
    if (entry != null) {
      final dedupeKey = entry.options.key;
      if (dedupeKey != null) _keyToId.remove(dedupeKey);

      if (_config.enableHistory) {
        AwesomeHistory.instance.markDismissed(id);
      }
    }

    final anyStillExiting = _activeEntries.values.any((e) => e.isExiting);
    if (!anyStillExiting) _isExiting = false;

    _processQueue();
  }

  /// Called by the widget at the START of its exit animation.
  static void markExiting(String id) {
    final existing = _activeEntries[id];
    if (existing != null) {
      _isExiting = true;
      _activeEntries[id] = _ActiveEntry(
        id: existing.id,
        options: existing.options,
        dismiss: existing.dismiss,
        isExiting: true,
      );
    }
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
        await HapticFeedback.heavyImpact();
      case AwesomeHaptic.vibrate:
        await HapticFeedback.vibrate();
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
      // FIX: Use the caller's duration if provided; otherwise fall back to
      // the global config duration, NOT a hardcoded 4-second default.
      // Previously this was hardcoded to Duration(seconds: 4), which meant
      // setting a shorter duration in AwesomeOptions was silently overridden
      // whenever using the convenience methods (success/error/warning/info).
      duration: base?.duration ?? _config.duration,
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
    required this.isExiting,
  });
  final String id;
  final AwesomeOptions options;
  final VoidCallback dismiss;
  final bool isExiting;
}

// ─── Shared stream bridge ────────────────────────────────────────────────────

/// Event emitted when a notification should be displayed.
class AwesomeShowEvent {
  const AwesomeShowEvent({required this.id, required this.options});
  final String id;
  final AwesomeOptions options;
}

/// Singleton stream controller shared between [AwesomeSnackbar] and [AwesomeWidget].
class AwesomeController {
  AwesomeController._();
  static final AwesomeController _instance = AwesomeController._();

  final StreamController<AwesomeShowEvent> _ctrl =
      StreamController<AwesomeShowEvent>.broadcast();

  Stream<AwesomeShowEvent> get stream => _ctrl.stream;
  void _emit(AwesomeShowEvent event) => _ctrl.add(event);

  static Stream<AwesomeShowEvent> get events => _instance.stream;
}
