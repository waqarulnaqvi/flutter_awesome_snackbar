import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'awesome_config.dart';
import 'awesome_options.dart';
import 'awesome_snackbar.dart';
import 'enums/awesome_animation.dart';
import 'enums/awesome_dismiss_direction.dart';
import 'enums/awesome_position.dart';
import 'enums/awesome_type.dart';

/// Wrap your [MaterialApp.builder] with this to enable notifications.
///
/// ```dart
/// MaterialApp(
///   builder: AwesomeWidget.init(),
///   home: HomeScreen(),
/// )
/// ```
class AwesomeWidget extends StatefulWidget {
  const AwesomeWidget({
    super.key,
    required this.child,
    this.config,
  });

  final Widget child;
  final AwesomeConfig? config;

  /// Returns a [TransitionBuilder] for [MaterialApp.builder].
  static TransitionBuilder init({AwesomeConfig? config}) {
    return (context, child) {
      if (config != null) AwesomeSnackbar.configure(config);
      return AwesomeWidget(
        config: config,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  State<AwesomeWidget> createState() => _AwesomeWidgetState();
}

class _AwesomeWidgetState extends State<AwesomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(builder: (_) => widget.child),
        OverlayEntry(builder: (_) => const _AwesomeNotificationHost()),
      ],
    );
  }
}

// ─── Notification host ───────────────────────────────────────────────────────

class _AwesomeNotificationHost extends StatefulWidget {
  const _AwesomeNotificationHost();

  @override
  State<_AwesomeNotificationHost> createState() =>
      _AwesomeNotificationHostState();
}

class _AwesomeNotificationHostState extends State<_AwesomeNotificationHost> {
  final _active = <String, _NotificationEntry>{};
  late final StreamSubscription<AwesomeShowEvent> _sub;

  @override
  void initState() {
    super.initState();
    _sub = AwesomeController.events.listen(_onShow);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onShow(AwesomeShowEvent event) {
    if (!mounted) return;
    if (_active.containsKey(event.id)) return;
    setState(() {
      _active[event.id] = _NotificationEntry(
        id: event.id,
        options: event.options,
        onDone: _remove,
      );
    });
  }

  void _remove(String id) {
    if (!mounted) return;
    setState(() => _active.remove(id));
    AwesomeSnackbar.unregisterActive(id);
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();

    final config = AwesomeSnackbar.config;
    final entries = _active.values.take(config.maxVisible).toList();

    return IgnorePointer(
      ignoring: config.tapThroughEnabled,
      child: Stack(
        fit: StackFit.expand,
        children: entries
            .asMap()
            .entries
            .map((e) => _positionedCard(e.value, e.key, config))
            .toList(),
      ),
    );
  }

  Widget _positionedCard(
    _NotificationEntry entry,
    int index,
    AwesomeConfig config,
  ) {
    final safeArea =
        config.safeAreaInsets ? MediaQuery.of(context).padding : EdgeInsets.zero;

    const baseGap = 16.0;
    final stackOffset = index * 8.0;

    AlignmentGeometry alignment;
    EdgeInsets padding;

    switch (config.position) {
      case AwesomePosition.top:
        alignment = Alignment.topCenter;
        padding = EdgeInsets.only(top: safeArea.top + baseGap + stackOffset);
      case AwesomePosition.bottom:
        alignment = Alignment.bottomCenter;
        padding =
            EdgeInsets.only(bottom: safeArea.bottom + baseGap + stackOffset);
      case AwesomePosition.center:
        alignment = Alignment.center;
        padding = EdgeInsets.zero;
      case AwesomePosition.topLeft:
        alignment = Alignment.topLeft;
        padding = EdgeInsets.only(top: safeArea.top + baseGap, left: 16);
      case AwesomePosition.topRight:
        alignment = Alignment.topRight;
        padding = EdgeInsets.only(top: safeArea.top + baseGap, right: 16);
      case AwesomePosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        padding =
            EdgeInsets.only(bottom: safeArea.bottom + baseGap, left: 16);
      case AwesomePosition.bottomRight:
        alignment = Alignment.bottomRight;
        padding =
            EdgeInsets.only(bottom: safeArea.bottom + baseGap, right: 16);
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: _AnimatedNotificationCard(entry: entry),
      ),
    );
  }
}

// ─── Animated card wrapper ────────────────────────────────────────────────────

class _AnimatedNotificationCard extends StatefulWidget {
  const _AnimatedNotificationCard({required this.entry});

  final _NotificationEntry entry;

  @override
  State<_AnimatedNotificationCard> createState() =>
      _AnimatedNotificationCardState();
}

class _AnimatedNotificationCardState extends State<_AnimatedNotificationCard>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _progressCtrl;

  Timer? _autoDismissTimer;

  // *** FIX 1 — DOUBLE-TAP FREEZE ***
  // The guard flag must be set SYNCHRONOUSLY at the very start of _dismiss(),
  // before any await. In the old code the flag was set after `await _ctrl.reverse()`,
  // meaning a second tap could enter _dismiss() while the first was still
  // awaiting the reverse animation, spawning two concurrent reverses.
  // Two concurrent AnimationController.reverse() calls on the same controller
  // left it in an irrecoverable "stuck" state and onDone was never called,
  // freezing the snackbar on screen forever.
  bool _dismissCalled = false;

  @override
  void initState() {
    super.initState();
    final config = AwesomeSnackbar.config;
    final opts = widget.entry.options;

    _ctrl = AnimationController(
      vsync: this,
      duration: config.animationDuration,
      reverseDuration:
          config.animationReverseDuration ?? config.animationDuration,
    );

    _progressCtrl = AnimationController(
      vsync: this,
      // *** FIX 2 — DURATION ***
      // Use opts.duration so that a 1-second duration actually counts down in
      // 1 second. Previously this was set to opts.duration on the controller
      // but _merge() always fell back to Duration(seconds: 4) when no base
      // options was provided, so the user's duration was silently discarded.
      // That bug is fixed in awesome_snackbar.dart (_merge now reads from
      // _config.duration rather than hardcoding 4 seconds), but we also
      // explicitly set reverseDuration here so the countdown bar is correct.
      duration: opts.duration,
      reverseDuration: opts.duration,
    );

    // Register our dismiss callback BEFORE starting the entrance animation.
    // This ensures dismissById() always finds a real callback even if it is
    // called in the same frame as show() (e.g. for loader patterns).
    AwesomeSnackbar.registerActive(widget.entry.id, _dismiss);

    // Start entrance animation.
    _ctrl.forward();

    final persistent = opts.persistent || opts.duration == Duration.zero;
    if (!persistent) {
      // Start progress bar at 1.0 and reverse to 0.0 (depletes visually).
      _progressCtrl.value = 1.0;
      _progressCtrl.reverse();

      // *** FIX 3 — DURATION TIMER ***
      // The timer was already using opts.duration, but because _merge() was
      // hardcoding 4 seconds in the old code, opts.duration was always 4 s
      // regardless of what the caller passed. Now that _merge() is fixed, the
      // timer here correctly fires after whatever duration was requested.
      _autoDismissTimer = Timer(opts.duration, _dismiss);
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _ctrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    // *** FIX 1 (continued) — set the guard FIRST, synchronously, before any
    // await. This is the critical change: the old code placed this AFTER
    // `await _ctrl.reverse()`, so a second call could slip in during the
    // animation and run a second reverse(), corrupting the controller state.
    if (_dismissCalled) return;
    _dismissCalled = true;

    _autoDismissTimer?.cancel();
    _progressCtrl.stop();

    // Mark this slot as exiting so _processQueue() doesn't promote the next
    // item until the exit animation is done.
    AwesomeSnackbar.markExiting(widget.entry.id);

    if (!mounted) {
      widget.entry.options.onDismiss?.call();
      widget.entry.onDone(widget.entry.id);
      return;
    }

    // Only reverse if the controller is in a reversible state (forwarding or
    // completed). If it's already dismissed/stopped, skip to avoid exceptions.
    if (_ctrl.status == AnimationStatus.forward ||
        _ctrl.status == AnimationStatus.completed) {
      await _ctrl.reverse();
    }

    widget.entry.options.onDismiss?.call();

    if (!mounted) {
      widget.entry.onDone(widget.entry.id);
      return;
    }

    widget.entry.onDone(widget.entry.id);
  }

  Widget _applyAnimation(Widget child) {
    final opts = widget.entry.options;
    final animation = opts.animation ?? AwesomeSnackbar.config.animation;

    if (opts.animationBuilder != null) {
      return opts.animationBuilder!(_ctrl, child);
    }

    switch (animation) {
      case AwesomeAnimation.fade:
        return FadeTransition(opacity: _ctrl, child: child);

      case AwesomeAnimation.scale:
        return ScaleTransition(
          scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
          child: child,
        );

      case AwesomeAnimation.elastic:
        return SlideTransition(
          position: Tween(begin: const Offset(0, -1.5), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)),
          child: child,
        );

      case AwesomeAnimation.bounce:
        return SlideTransition(
          position: Tween(begin: const Offset(0, -1.2), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut)),
          child: child,
        );

      case AwesomeAnimation.rotation:
        return RotationTransition(
          turns: Tween(begin: 0.05, end: 0.0).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: _ctrl, child: child),
        );

      case AwesomeAnimation.ios:
        return SlideTransition(
          position: Tween(begin: const Offset(0, -1.0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: _ctrl,
                  curve: const Cubic(0.25, 0.46, 0.45, 0.94))),
          child: child,
        );

      case AwesomeAnimation.flip:
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, ch) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX((1 - _ctrl.value) * 1.5708),
            child: ch,
          ),
          child: child,
        );

      case AwesomeAnimation.path:
        final path = opts.pathAnimation;
        if (path != null) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, ch) {
              final metrics = path.computeMetrics().first;
              final tangent =
                  metrics.getTangentForOffset(metrics.length * _ctrl.value);
              final pos = tangent?.position ?? Offset.zero;
              return Transform.translate(offset: pos, child: ch);
            },
            child: child,
          );
        }
        return SlideTransition(
          position: Tween(begin: const Offset(0, -1.0), end: Offset.zero)
              .animate(_ctrl),
          child: child,
        );

      case AwesomeAnimation.slide:
        return SlideTransition(
          position: Tween(begin: const Offset(0, -1.0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final opts = widget.entry.options;
    final config = AwesomeSnackbar.config;
    final dismissDir = opts.dismissDirection ?? config.dismissDirection;

    Widget card = _NotificationCard(
      entry: widget.entry,
      onDismiss: _dismiss,
      progressController: _progressCtrl,
    );

    if (dismissDir != AwesomeDismissDirection.none) {
      card = Dismissible(
        key: ValueKey(widget.entry.id),
        direction: _toFlutterDirection(dismissDir),
        // *** FIX 1 (Dismissible) ***
        // Dismissible calls onDismissed after its own animation finishes.
        // We must NOT call _dismiss() here if it was already called by a tap
        // (the _dismissCalled guard handles this), but we must always call
        // onDone so the entry is cleaned up. Since _dismiss() is already
        // guarded, calling it is safe — it will no-op on the second call.
        onDismissed: (_) => _dismiss(),
        child: card,
      );
    }

    return _applyAnimation(card);
  }

  DismissDirection _toFlutterDirection(AwesomeDismissDirection dir) {
    switch (dir) {
      case AwesomeDismissDirection.horizontal:
        return DismissDirection.horizontal;
      case AwesomeDismissDirection.vertical:
        return DismissDirection.vertical;
      case AwesomeDismissDirection.any:
        return DismissDirection.startToEnd;
      case AwesomeDismissDirection.none:
        return DismissDirection.none;
    }
  }
}

// ─── Visual card ─────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.entry,
    required this.onDismiss,
    required this.progressController,
  });

  final _NotificationEntry entry;
  final VoidCallback onDismiss;
  final AnimationController progressController;

  @override
  Widget build(BuildContext context) {
    final opts = entry.options;
    final config = AwesomeSnackbar.config;
    final theme = opts.themeData ?? config.defaultTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = _typeColors(opts.type, isDark);
    final bgColor = theme?.backgroundColor ?? colors.bg;
    final textColor = theme?.textColor ?? colors.text;
    final iconColor = theme?.iconColor ?? colors.icon;
    final progressColor = theme?.progressColor ?? colors.icon;
    final borderColor = theme?.borderColor;
    final borderWidth = theme?.borderWidth ?? 0.0;

    final maxWidth = opts.maxWidth ?? config.maxWidth ?? 480.0;
    final borderRadius =
        opts.borderRadius ?? config.borderRadius ?? BorderRadius.circular(14);
    final margin = opts.margin ??
        config.margin ??
        const EdgeInsets.symmetric(horizontal: 16);

    Widget cardContent = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: margin,
      decoration: BoxDecoration(
        gradient: theme?.gradient,
        color: theme?.gradient != null
            ? null
            : bgColor.withValues(alpha: theme?.backgroundOpacity ?? 1.0),
        borderRadius: borderRadius,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: opts.onTap != null || opts.routeName != null
              ? () {
                  if (opts.routeName != null) {
                    AwesomeSnackbar.navigatorKey.currentState
                        ?.pushNamed(opts.routeName!);
                  }
                  opts.onTap?.call();
                  if (opts.dismissOnTap) onDismiss();
                }
              : null,
          child: Padding(
            padding: opts.padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: opts.customWidget != null
                ? opts.customWidget!
                : _DefaultContent(
                    opts: opts,
                    textColor: textColor,
                    iconColor: iconColor,
                    progressColor: progressColor,
                    progressController: progressController,
                    onDismiss: onDismiss,
                  ),
          ),
        ),
      ),
    );

    final useBlur = config.blur ||
        (theme?.backgroundOpacity != null && theme!.backgroundOpacity! < 1.0);
    if (useBlur) {
      cardContent = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: cardContent,
        ),
      );
    }

    return Semantics(
      label: opts.accessibilityLabel ??
          '${opts.type.name}: ${opts.title ?? ''} ${opts.message ?? ''}',
      liveRegion: true,
      child: cardContent,
    );
  }
}

// ─── Default card content ─────────────────────────────────────────────────────

class _DefaultContent extends StatelessWidget {
  const _DefaultContent({
    required this.opts,
    required this.textColor,
    required this.iconColor,
    required this.progressColor,
    required this.progressController,
    required this.onDismiss,
  });

  final AwesomeOptions opts;
  final Color textColor;
  final Color iconColor;
  final Color progressColor;
  final AnimationController progressController;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: _resolveIcon(),
            ),

            // Title + message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (opts.title != null)
                    Text(
                      opts.title!,
                      style: TextStyle(
                        color: opts.themeData?.titleColor ?? textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: opts.themeData?.titleFontSize ?? 14,
                      ),
                    ),
                  if (opts.message != null)
                    Padding(
                      padding:
                          EdgeInsets.only(top: opts.title != null ? 2 : 0),
                      child: Text(
                        opts.message!,
                        style: TextStyle(
                          color: textColor,
                          fontSize: opts.themeData?.messageFontSize ?? 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (opts.showTimestamp ||
                      AwesomeSnackbar.config.showTimestamp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'just now',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Dismiss ×
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close,
                    size: 16, color: textColor.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),

        // Action buttons
        if (opts.actionText != null || opts.secondaryActionText != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                if (opts.actionText != null)
                  _ActionButton(
                    label: opts.actionText!,
                    color: opts.themeData?.actionColor ?? iconColor,
                    onTap: opts.onAction,
                  ),
                if (opts.secondaryActionText != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: opts.secondaryActionText!,
                    color: opts.themeData?.secondaryActionColor ??
                        textColor.withValues(alpha: 0.7),
                    onTap: opts.onSecondaryAction,
                  ),
                ],
              ],
            ),
          ),

        // Progress bar — depletes from full to empty over [duration].
        if ((opts.showProgress || AwesomeSnackbar.config.showProgress) &&
            !opts.persistent &&
            opts.duration != Duration.zero)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedBuilder(
              animation: progressController,
              builder: (_, __) => LinearProgressIndicator(
                value: progressController.value,
                backgroundColor: progressColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resolveIcon() {
    final size = opts.themeData?.iconSize ?? 22.0;

    if (opts.iconWidget != null) {
      return SizedBox(width: size, height: size, child: opts.iconWidget!);
    }

    if (opts.iconAsset != null) {
      return Image.asset(
        opts.iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            _TypeIcon(type: opts.type, color: iconColor, size: size),
      );
    }

    if (opts.iconNetwork != null) {
      return Image.network(
        opts.iconNetwork!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
        errorBuilder: (_, __, ___) =>
            _TypeIcon(type: opts.type, color: iconColor, size: size),
      );
    }

    if (opts.iconProvider != null) {
      return Image(
        image: opts.iconProvider!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            _TypeIcon(type: opts.type, color: iconColor, size: size),
      );
    }

    return _TypeIcon(type: opts.type, color: iconColor, size: size);
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Type icon ────────────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({
    required this.type,
    required this.color,
    required this.size,
  });

  final AwesomeType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AwesomeType.loading:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case AwesomeType.success:
        return Icon(Icons.check_circle_outline_rounded,
            color: color, size: size);
      case AwesomeType.error:
        return Icon(Icons.error_outline_rounded, color: color, size: size);
      case AwesomeType.warning:
        return Icon(Icons.warning_amber_rounded, color: color, size: size);
      case AwesomeType.info:
      case AwesomeType.custom:
        return Icon(Icons.info_outline_rounded, color: color, size: size);
    }
  }
}

// ─── Type colour palette ──────────────────────────────────────────────────────

class _TypeColors {
  const _TypeColors({
    required this.bg,
    required this.text,
    required this.icon,
  });
  final Color bg;
  final Color text;
  final Color icon;
}

_TypeColors _typeColors(AwesomeType type, bool dark) {
  switch (type) {
    case AwesomeType.success:
      return dark
          ? const _TypeColors(
              bg: Color(0xFF14532D),
              text: Color(0xFFBBF7D0),
              icon: Color(0xFF4ADE80))
          : const _TypeColors(
              bg: Color(0xFFF0FDF4),
              text: Color(0xFF166534),
              icon: Color(0xFF16A34A));
    case AwesomeType.error:
      return dark
          ? const _TypeColors(
              bg: Color(0xFF450A0A),
              text: Color(0xFFFECACA),
              icon: Color(0xFFF87171))
          : const _TypeColors(
              bg: Color(0xFFFFF1F2),
              text: Color(0xFF991B1B),
              icon: Color(0xFFDC2626));
    case AwesomeType.warning:
      return dark
          ? const _TypeColors(
              bg: Color(0xFF431407),
              text: Color(0xFFFED7AA),
              icon: Color(0xFFFB923C))
          : const _TypeColors(
              bg: Color(0xFFFFFBEB),
              text: Color(0xFF92400E),
              icon: Color(0xFFD97706));
    case AwesomeType.loading:
    case AwesomeType.info:
    case AwesomeType.custom:
      return dark
          ? const _TypeColors(
              bg: Color(0xFF1E3A5F),
              text: Color(0xFFBAE6FD),
              icon: Color(0xFF38BDF8))
          : const _TypeColors(
              bg: Color(0xFFEFF6FF),
              text: Color(0xFF1E40AF),
              icon: Color(0xFF3B82F6));
  }
}

// ─── Internal entry type ─────────────────────────────────────────────────────

class _NotificationEntry {
  const _NotificationEntry({
    required this.id,
    required this.options,
    required this.onDone,
  });

  final String id;
  final AwesomeOptions options;
  final void Function(String id) onDone;
}
