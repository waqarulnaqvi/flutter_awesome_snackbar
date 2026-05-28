import 'package:flutter/material.dart';

import 'awesome_theme.dart';
import 'enums/awesome_type.dart';
import 'enums/awesome_position.dart';
import 'enums/awesome_animation.dart';
import 'enums/awesome_priority.dart';
import 'enums/awesome_dismiss_direction.dart';
import 'enums/awesome_haptic.dart';

/// Full configuration for a single notification.
class AwesomeOptions {
  const AwesomeOptions({
    this.title,
    this.message,
    this.type = AwesomeType.info,
    this.position,
    this.animation,
    this.animationBuilder,
    this.pathAnimation,
    this.duration = const Duration(seconds: 4),
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.showProgress = false,
    this.dismissDirection,
    this.priority = AwesomePriority.normal,
    this.key,
    this.icon,
    this.customWidget,
    this.themeData,
    this.haptic,
    this.onTap,
    this.onDismiss,
    this.routeName,
    this.groupKey,
    this.dismissOnTap = false,
    this.persistent = false,
    this.tag,
    this.maxWidth,
    this.borderRadius,
    this.margin,
    this.padding,
    this.showTimestamp = false,
    this.accessibilityLabel,
  });

  // ─── Content ─────────────────────────────────────────────────────────────

  /// Optional title shown above [message].
  final String? title;

  /// Main notification body.
  final String? message;

  /// Semantic type; controls default icon and colours.
  final AwesomeType type;

  // ─── Appearance ──────────────────────────────────────────────────────────

  /// Override the global position for this notification.
  final AwesomePosition? position;

  /// Override the global animation for this notification.
  final AwesomeAnimation? animation;

  /// Custom animation builder — overrides [animation].
  ///
  /// ```dart
  /// animationBuilder: (controller, child) => SlideTransition(
  ///   position: Tween(begin: Offset(-2, 0), end: Offset.zero)
  ///     .animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut)),
  ///   child: child,
  /// ),
  /// ```
  final Widget Function(AnimationController controller, Widget child)?
      animationBuilder;

  /// Custom enter/exit path for [AwesomeAnimation.path].
  ///
  /// The notification follows this [Path] when entering and reverses on dismiss.
  final Path? pathAnimation;

  /// How long the notification stays visible.
  final Duration duration;

  /// Optional per-notification theme overrides.
  final AwesomeThemeData? themeData;

  /// Fully custom widget — replaces icon + title + message.
  final Widget? customWidget;

  /// Custom leading icon widget.
  final Widget? icon;

  /// Max width of the notification card in logical pixels.
  final double? maxWidth;

  /// Override border radius.
  final BorderRadius? borderRadius;

  /// Outer margin around the notification.
  final EdgeInsets? margin;

  /// Inner padding of the notification card.
  final EdgeInsets? padding;

  /// Whether to show a timestamp ("just now", "2 m ago", …).
  final bool showTimestamp;

  // ─── Actions ─────────────────────────────────────────────────────────────

  /// Text for the primary action button.
  final String? actionText;

  /// Callback for the primary action button.
  final VoidCallback? onAction;

  /// Text for the secondary action button.
  final String? secondaryActionText;

  /// Callback for the secondary action button.
  final VoidCallback? onSecondaryAction;

  // ─── Behaviour ───────────────────────────────────────────────────────────

  /// Show an animated progress bar that depletes over [duration].
  final bool showProgress;

  /// Swipe-to-dismiss direction. Defaults to global config.
  final AwesomeDismissDirection? dismissDirection;

  /// Queue priority.
  final AwesomePriority priority;

  /// Unique key for duplicate prevention.
  ///
  /// If a notification with this key is already visible or queued,
  /// the new one is silently dropped.
  final String? key;

  /// Notification tap callback.
  final VoidCallback? onTap;

  /// Dismiss callback — fired when the notification leaves the screen.
  final VoidCallback? onDismiss;

  /// Dismiss the notification when the user taps anywhere on it.
  final bool dismissOnTap;

  /// If `true`, the notification never auto-dismisses.
  final bool persistent;

  // ─── Extras ──────────────────────────────────────────────────────────────

  /// Haptic feedback to trigger when the notification appears.
  ///
  /// Uses Flutter's built-in [HapticFeedback] — no external package required.
  final AwesomeHaptic? haptic;

  /// Named route to push when the user taps the notification.
  ///
  /// Overrides [onTap] navigation if both are set.
  final String? routeName;

  /// Group key for collapsing related notifications.
  final String? groupKey;

  /// Arbitrary tag for filtering the history panel.
  final String? tag;

  /// Accessibility label read by screen readers.
  ///
  /// Defaults to "[type.name]: $title $message".
  final String? accessibilityLabel;
}
