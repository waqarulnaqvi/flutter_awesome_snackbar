import 'package:flutter/material.dart';

import 'awesome_theme.dart';
import 'enums/awesome_animation.dart';
import 'enums/awesome_dismiss_direction.dart';
import 'enums/awesome_haptic.dart';
import 'enums/awesome_position.dart';
import 'enums/awesome_priority.dart';
import 'enums/awesome_type.dart';

/// Full configuration for a single notification.
///
/// ### Icon options (pick at most one; [iconWidget] takes priority)
///
/// | Field          | Use case                                        |
/// |----------------|-------------------------------------------------|
/// | [iconWidget]   | Any Flutter widget (Icon, SvgPicture, Lottie…)  |
/// | [iconAsset]    | Asset image path — `"assets/icons/star.png"`    |
/// | [iconNetwork]  | Remote image URL — `"https://…/icon.png"`       |
/// | [iconProvider] | Any [ImageProvider] (AssetImage, NetworkImage…) |
///
/// All four accept optional [iconSize] and [iconColor] from [AwesomeThemeData].
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
    // ── icon variants ──────────────────────────────────────────────────────
    this.iconWidget,
    this.iconAsset,
    this.iconNetwork,
    this.iconProvider,
    // ──────────────────────────────────────────────────────────────────────
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
  final Widget Function(AnimationController controller, Widget child)?
  animationBuilder;

  /// Custom enter/exit path for [AwesomeAnimation.path].
  final Path? pathAnimation;

  /// How long the notification stays visible.
  final Duration duration;

  /// Optional per-notification theme overrides.
  final AwesomeThemeData? themeData;

  /// Fully custom widget — replaces icon + title + message.
  final Widget? customWidget;

  // ─── Icon (pick one) ─────────────────────────────────────────────────────

  /// Any Flutter widget used as the leading icon.
  ///
  /// Supports `Icon`, `SvgPicture.asset(…)`, `Lottie.asset(…)`,
  /// `Image.asset(…)`, or anything else.
  ///
  /// ```dart
  /// iconWidget: const Icon(Icons.star, color: Colors.amber),
  /// iconWidget: SvgPicture.asset('assets/icons/star.svg', width: 22),
  /// ```
  final Widget? iconWidget;

  /// Path to a Flutter asset image (PNG / JPG / GIF / WebP).
  ///
  /// ```dart
  /// iconAsset: 'assets/icons/check.png',
  /// ```
  final String? iconAsset;

  /// URL of a network image.
  ///
  /// ```dart
  /// iconNetwork: 'https://example.com/icons/alert.png',
  /// ```
  final String? iconNetwork;

  /// Any [ImageProvider] — [AssetImage], [NetworkImage], [MemoryImage], etc.
  ///
  /// ```dart
  /// iconProvider: const AssetImage('assets/icons/check.png'),
  /// iconProvider: NetworkImage('https://example.com/icon.png'),
  /// ```
  final ImageProvider? iconProvider;

  // ─── Layout ──────────────────────────────────────────────────────────────

  /// Max width of the notification card in logical pixels.
  final double? maxWidth;

  /// Override border radius.
  final BorderRadius? borderRadius;

  /// Outer margin around the notification.
  final EdgeInsets? margin;

  /// Inner padding of the notification card.
  final EdgeInsets? padding;

  /// Whether to show a relative timestamp ("just now", "2 m ago", …).
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
  final AwesomeHaptic? haptic;

  /// Named route to push when the user taps the notification.
  final String? routeName;

  /// Group key for collapsing related notifications.
  final String? groupKey;

  /// Arbitrary tag for filtering the history panel.
  final String? tag;

  /// Accessibility label read by screen readers.
  final String? accessibilityLabel;
}