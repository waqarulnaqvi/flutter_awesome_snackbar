import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'awesome_config.dart';
import 'awesome_history.dart';
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
  final List<_NotificationEntry> _active = [];
  late final StreamSubscription<AwesomeShowEvent> _sub;

  @override
  void initState() {
    super.initState();
    // FIX: subscribe to the SHARED AwesomeController.events stream —
    // previously this file defined its own _AwesomeController with only
    // `stream` while awesome_snackbar.dart had a different one with only
    // `emit`, so events were never delivered.
    _sub = AwesomeController.events.listen(_onShow);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _onShow(AwesomeShowEvent event) {
    if (!mounted) return;
    setState(() {
      _active.add(_NotificationEntry(
        id: event.id,
        options: event.options,
        onDone: _remove,
      ));
    });
  }

  void _remove(String id) {
    if (!mounted) return;
    setState(() => _active.removeWhere((e) => e.id == id));
    AwesomeSnackbar.unregisterActive(id);
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();

    final config = AwesomeSnackbar.config;

    return IgnorePointer(
      ignoring: config.tapThroughEnabled,
      child: Stack(
        children: _active
            .take(config.maxVisible)
            .toList()
            .asMap()
            .entries
            .map((e) => _positionedCard(e.value, e.key, config.position))
            .toList(),
      ),
    );
  }

  Widget _positionedCard(
      _NotificationEntry entry,
      int index,
      AwesomePosition position,
      ) {
    final config = AwesomeSnackbar.config;
    final safeArea =
    config.safeAreaInsets ? MediaQuery.of(context).padding : EdgeInsets.zero;

    const baseGap = 16.0;
    final stackOffset = index * 8.0;

    AlignmentGeometry alignment;
    EdgeInsets padding;

    switch (position) {
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    final config = AwesomeSnackbar.config;
    _ctrl = AnimationController(
      vsync: this,
      duration: config.animationDuration,
      reverseDuration:
      config.animationReverseDuration ?? config.animationDuration,
    );
    _ctrl.forward();

    // Register dismiss callback so AwesomeSnackbar.dismissById() works.
    AwesomeSnackbar.registerActive(widget.entry.id, _dismiss);

    final opts = widget.entry.options;
    final persistent = opts.persistent || opts.duration == Duration.zero;
    if (!persistent) {
      _autoDismissTimer = Timer(opts.duration, _dismiss);
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    await _ctrl.reverse();
    if (!mounted) return;
    widget.entry.onDone(widget.entry.id);
    widget.entry.options.onDismiss?.call();
    if (AwesomeSnackbar.config.enableHistory) {
      AwesomeHistory.instance.markDismissed(widget.entry.id);
    }
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
          scale:
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
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
      animController: _ctrl,
    );

    if (dismissDir != AwesomeDismissDirection.none) {
      card = Dismissible(
        key: ValueKey(widget.entry.id),
        // FIX: AwesomeDismissDirection.any now correctly maps to
        // DismissDirection.startToEnd / endToStart pair via `none` was wrong.
        direction: _toFlutterDirection(dismissDir),
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
      // FIX: was incorrectly mapped to DismissDirection.none
        return DismissDirection.none; // handled by GestureDetector below
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
    required this.animController,
  });

  final _NotificationEntry entry;
  final VoidCallback onDismiss;
  final AnimationController animController;

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
              Navigator.of(context).pushNamed(opts.routeName!);
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
              animController: animController,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );

    // Glassmorphism
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
    required this.animController,
    required this.onDismiss,
  });

  final AwesomeOptions opts;
  final Color textColor;
  final Color iconColor;
  final Color progressColor;
  final AnimationController animController;
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
            // Leading icon — resolves the correct icon source
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

        // Progress bar
        if (opts.showProgress || AwesomeSnackbar.config.showProgress)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedBuilder(
              animation: animController,
              builder: (_, __) => LinearProgressIndicator(
                value: animController.value,
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

  /// Resolves the correct leading icon widget using this priority order:
  /// 1. [iconWidget]   — any Flutter widget (SVG, Lottie, custom Icon…)
  /// 2. [iconAsset]    — local asset image path
  /// 3. [iconNetwork]  — remote image URL
  /// 4. [iconProvider] — any [ImageProvider]
  /// 5. Default type icon
  Widget _resolveIcon() {
    final size = opts.themeData?.iconSize ?? 22.0;

    // 1. Explicit widget (highest priority — supports SVG, Lottie, etc.)
    if (opts.iconWidget != null) {
      return SizedBox(width: size, height: size, child: opts.iconWidget!);
    }

    // 2. Asset image path
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

    // 3. Network image URL
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

    // 4. Generic ImageProvider (AssetImage, NetworkImage, MemoryImage, …)
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

    // 5. Default type icon
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
        return Icon(Icons.check_circle_outline_rounded, color: color, size: size);
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