import 'dart:math' as math;
import 'package:flutter/material.dart';

class MinimalLoadingDots extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const MinimalLoadingDots({
    super.key,
    this.color,
    this.dotSize = 7.0,
  });

  @override
  State<MinimalLoadingDots> createState() => _MinimalLoadingDotsState();
}

class _MinimalLoadingDotsState extends State<MinimalLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? Colors.white.withValues(alpha: 0.85);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final double progress = (_controller.value - delay) % 1.0;
            final double scale = 0.6 + 0.5 * math.sin(progress * math.pi);
            final double opacity = (0.3 + 0.7 * math.sin(progress * math.pi)).clamp(0.2, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: widget.dotSize,
              height: widget.dotSize,
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: opacity),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: opacity * 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
