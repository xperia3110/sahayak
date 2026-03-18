
import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    // Initialize bubbles
    for (int i = 0; i < 20; i++) {
        _bubbles.add(_generateBubble());
    }
  }

  _Bubble _generateBubble() {
    return _Bubble(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 50 + 20,
      speed: _random.nextDouble() * 0.2 + 0.05,
      color: Colors.white.withOpacity(0.1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A1B9A), // Deep Purple
                Color(0xFFAB47BC), // Lighter Purple
                Color(0xFF26C6DA), // Cyan
              ],
            ),
          ),
        ),
        
        // Floating Bubbles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BubblePainter(_bubbles, _controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _Bubble {
  double x;
  double y;
  double size;
  double speed;
  Color color;

  _Bubble({required this.x, required this.y, required this.size, required this.speed, required this.color});
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double animationValue;

  _BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      // Move bubble up
      double currentY = bubble.y - (bubble.speed * animationValue * 5); // 5 is a multiplier
      
      // Wrap around
      currentY = currentY % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Slight horizontal wobble
      double currentX = bubble.x + sin(animationValue * 2 * pi * bubble.speed) * 0.05;

      paint.color = bubble.color;
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        bubble.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
