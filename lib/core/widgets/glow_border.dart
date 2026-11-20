import 'package:flutter/material.dart';
import 'package:aetherssh/core/theme/app_theme.dart';

class GlowBorder extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final Color? color;
  final double borderWidth;
  final bool showGlow;

  const GlowBorder({
    super.key,
    required this.child,
    this.borderRadius,
    this.color,
    this.borderWidth = 1.0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? 20.0;
    final effectiveColor = color ?? AppTheme.cardBackground;

    return Container(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
