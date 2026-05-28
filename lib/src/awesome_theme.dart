import 'package:flutter/material.dart';

/// Per-notification visual overrides.
class AwesomeThemeData {
  const AwesomeThemeData({
    this.backgroundColor,
    this.textColor,
    this.titleColor,
    this.iconColor,
    this.actionColor,
    this.secondaryActionColor,
    this.progressColor,
    this.borderColor,
    this.borderWidth,
    this.gradient,
    this.backgroundOpacity,
    this.iconSize,
    this.titleFontSize,
    this.messageFontSize,
    this.elevation,
  });

  final Color? backgroundColor;
  final Color? textColor;
  final Color? titleColor;
  final Color? iconColor;
  final Color? actionColor;
  final Color? secondaryActionColor;
  final Color? progressColor;
  final Color? borderColor;
  final double? borderWidth;
  final Gradient? gradient;
  final double? backgroundOpacity;
  final double? iconSize;
  final double? titleFontSize;
  final double? messageFontSize;
  final double? elevation;

  /// Glassmorphism — frosted light / dark.
  factory AwesomeThemeData.glassSuccess({bool dark = false}) => AwesomeThemeData(
        backgroundColor: dark ? Colors.black38 : Colors.white38,
        textColor: dark ? Colors.white : Colors.black87,
        iconColor: const Color(0xFF22C55E),
        progressColor: const Color(0xFF22C55E),
        backgroundOpacity: 0.55,
      );

  /// Glassmorphism — frosted error.
  factory AwesomeThemeData.glassError({bool dark = false}) => AwesomeThemeData(
        backgroundColor: dark ? Colors.black38 : Colors.white38,
        textColor: dark ? Colors.white : Colors.black87,
        iconColor: const Color(0xFFEF4444),
        progressColor: const Color(0xFFEF4444),
        backgroundOpacity: 0.55,
      );

  AwesomeThemeData copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? titleColor,
    Color? iconColor,
    Color? actionColor,
    Color? secondaryActionColor,
    Color? progressColor,
    Color? borderColor,
    double? borderWidth,
    Gradient? gradient,
    double? backgroundOpacity,
    double? iconSize,
    double? titleFontSize,
    double? messageFontSize,
    double? elevation,
  }) {
    return AwesomeThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      titleColor: titleColor ?? this.titleColor,
      iconColor: iconColor ?? this.iconColor,
      actionColor: actionColor ?? this.actionColor,
      secondaryActionColor: secondaryActionColor ?? this.secondaryActionColor,
      progressColor: progressColor ?? this.progressColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      gradient: gradient ?? this.gradient,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      iconSize: iconSize ?? this.iconSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      messageFontSize: messageFontSize ?? this.messageFontSize,
      elevation: elevation ?? this.elevation,
    );
  }
}
