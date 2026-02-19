import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.maxWidth = 460,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6FFF8), Color(0xFFE9F7EF), Color(0xFFF0FDF4)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -35,
            child: _bubble(
              size: 180,
              color: const Color(0xFF8ED9A9).withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            left: -55,
            bottom: 60,
            child: _bubble(
              size: 140,
              color: const Color(0xFF3E8E62).withValues(alpha: 0.12),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
