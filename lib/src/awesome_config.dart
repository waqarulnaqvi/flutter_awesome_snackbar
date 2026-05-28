import 'package:flutter/material.dart';

import 'awesome_theme.dart';
import 'enums/awesome_animation.dart';
import 'enums/awesome_dismiss_direction.dart';
import 'enums/awesome_haptic.dart';
import 'enums/awesome_position.dart';

/// Global configuration applied to every notification unless overridden
/// by a per-notification [AwesomeOptions].
class AwesomeConfig {
  const AwesomeConfig({
    this.position = AwesomePosition.top,
    this.animation = AwesomeAnimation.slide,
    this.duration = const Duration(seconds: 4),
    this.borderRadius,
    this.blur = false,
    this.maxVisible = 3,
    this.stackedMode = false,
    this.showProgress = false,
    this.dismissDirection = AwesomeDismissDirection.horizontal,
    this.defaultHaptic = AwesomeHaptic.none,
    this.enableHistory = true,
    this.maxHistory = 100,
    this.showTimestamp = false,
    this.overlayOpacity = 0.0,
    this.defaultTheme,
    this.animationDuration = const Duration(milliseconds: 350),
    this.animationReverseDuration,
    this.maxWidth,
    this.margin,
    this.safeAreaInsets = true,
    this.groupSameKey = true,
    this.tapThroughEnabled = false,
  });

  // ─── Layout ──────────────────────────────────────────────────────────────

  /// Where notifications appear by default.
  final AwesomePosition position;

  /// Max notifications visible simultaneously.
  final int maxVisible;

  /// Show one notification at a time; others are queued.
  final bool stackedMode;

  /// Maximum width of notification cards (defaults to 480 logical pixels).
  final double? maxWidth;

  /// Outer margin around every notification.
  final EdgeInsets? margin;

  /// Respect `MediaQuery.of(context).padding` (notch, home bar).
  final bool safeAreaInsets;

  // ─── Animation ───────────────────────────────────────────────────────────

  /// Default entrance animation.
  final AwesomeAnimation animation;

  /// Duration of the entrance animation.
  final Duration animationDuration;

  /// Duration of the exit animation. Defaults to [animationDuration].
  final Duration? animationReverseDuration;

  // ─── Appearance ──────────────────────────────────────────────────────────

  /// Default card border radius.
  final BorderRadius? borderRadius;

  /// Enable glassmorphism (backdrop blur) globally.
  final bool blur;

  /// Default theme data overrides applied to every notification.
  final AwesomeThemeData? defaultTheme;

  /// Background scrim opacity behind notifications (0 = transparent, 1 = full).
  final double overlayOpacity;

  // ─── Behaviour ───────────────────────────────────────────────────────────

  /// Default display duration.
  final Duration duration;

  /// Show a progress bar by default.
  final bool showProgress;

  /// Default swipe-to-dismiss axis.
  final AwesomeDismissDirection dismissDirection;

  /// Allow taps to pass through notifications to widgets beneath.
  final bool tapThroughEnabled;

  /// Automatically group notifications sharing the same [AwesomeOptions.key].
  final bool groupSameKey;

  // ─── Haptic ──────────────────────────────────────────────────────────────

  /// Default haptic style for every notification.
  ///
  /// Uses Flutter's built-in [HapticFeedback] — no external package required.
  final AwesomeHaptic defaultHaptic;

  // ─── History ─────────────────────────────────────────────────────────────

  /// Record every shown notification in [AwesomeHistory].
  final bool enableHistory;

  /// Max records kept in [AwesomeHistory].
  final int maxHistory;

  /// Show a relative timestamp on every notification by default.
  final bool showTimestamp;

  AwesomeConfig copyWith({
    AwesomePosition? position,
    AwesomeAnimation? animation,
    Duration? duration,
    BorderRadius? borderRadius,
    bool? blur,
    int? maxVisible,
    bool? stackedMode,
    bool? showProgress,
    AwesomeDismissDirection? dismissDirection,
    AwesomeHaptic? defaultHaptic,
    bool? enableHistory,
    int? maxHistory,
    bool? showTimestamp,
    double? overlayOpacity,
    AwesomeThemeData? defaultTheme,
    Duration? animationDuration,
    Duration? animationReverseDuration,
    double? maxWidth,
    EdgeInsets? margin,
    bool? safeAreaInsets,
    bool? groupSameKey,
    bool? tapThroughEnabled,
  }) {
    return AwesomeConfig(
      position: position ?? this.position,
      animation: animation ?? this.animation,
      duration: duration ?? this.duration,
      borderRadius: borderRadius ?? this.borderRadius,
      blur: blur ?? this.blur,
      maxVisible: maxVisible ?? this.maxVisible,
      stackedMode: stackedMode ?? this.stackedMode,
      showProgress: showProgress ?? this.showProgress,
      dismissDirection: dismissDirection ?? this.dismissDirection,
      defaultHaptic: defaultHaptic ?? this.defaultHaptic,
      enableHistory: enableHistory ?? this.enableHistory,
      maxHistory: maxHistory ?? this.maxHistory,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      defaultTheme: defaultTheme ?? this.defaultTheme,
      animationDuration: animationDuration ?? this.animationDuration,
      animationReverseDuration:
          animationReverseDuration ?? this.animationReverseDuration,
      maxWidth: maxWidth ?? this.maxWidth,
      margin: margin ?? this.margin,
      safeAreaInsets: safeAreaInsets ?? this.safeAreaInsets,
      groupSameKey: groupSameKey ?? this.groupSameKey,
      tapThroughEnabled: tapThroughEnabled ?? this.tapThroughEnabled,
    );
  }
}
