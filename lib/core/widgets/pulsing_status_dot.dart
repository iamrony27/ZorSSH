import 'package:flutter/material.dart';

/// An animated status dot that smoothly pulses and blinks to indicate
/// live server connection status (Online green halo / Offline red halo).
/// Strictly self-contained to fit completely inside cards.
class PulsingStatusDot extends StatefulWidget {
  final bool isOnline;
  final double size;

  const PulsingStatusDot({
    super.key,
    required this.isOnline,
    this.size = 8.0,
  });

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isOnline ? 1200 : 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(PulsingStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _controller.duration = Duration(
        milliseconds: widget.isOnline ? 1200 : 2000,
      );
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isOnline
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);

    final glowColor = widget.isOnline
        ? const Color(0xFF00E676).withValues(alpha: 0.5)
        : const Color(0xFFFF5252).withValues(alpha: 0.4);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size + 8,
          height: widget.size + 8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(
                  alpha: glowColor.a * _pulseAnimation.value,
                ),
                blurRadius: 6 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor.withValues(
                alpha: 0.4 + (0.6 * _pulseAnimation.value),
              ),
            ),
          ),
        );
      },
    );
  }
}
