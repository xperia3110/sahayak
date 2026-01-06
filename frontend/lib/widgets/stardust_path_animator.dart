import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class StardustPathAnimator extends StatefulWidget {
  final Path path;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const StardustPathAnimator({
    super.key, 
    required this.path, 
    this.duration = const Duration(seconds: 4),
    this.onAnimationComplete,
  });

  @override
  State<StardustPathAnimator> createState() => _StardustPathAnimatorState();
}

class _StardustPathAnimatorState extends State<StardustPathAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().then((_) => widget.onAnimationComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _StardustPainter(widget.path, _controller.value),
        );
      },
    );
  }
}

class _StardustPainter extends CustomPainter {
  final Path path;
  final double progress;

  _StardustPainter(this.path, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw static Guide (Dashed semi-transparent)
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
      
   // Dash logic handled by simply drawing it faint for now. 
   // True dashed path in generic CustomPainter is verbose, so keeping it solid but faint.
   canvas.drawPath(path, guidePaint);

   if (progress <= 0 || progress >= 1) return;

   // 2. Draw Moving Stardust (Glowing Head + Trail)
   ui.PathMetric metric = path.computeMetrics().first;
   final double length = metric.length;
   final double currentDist = length * progress;
   
   // Leader Particle
   final ui.Tangent? tangent = metric.getTangentForOffset(currentDist);
   if (tangent != null) {
     final Offset pos = tangent.position;
     
     // Glow
     final glowPaint = Paint()
       ..color = Colors.cyanAccent
       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
     canvas.drawCircle(pos, 8, glowPaint);
     
     // Core
     final corePaint = Paint()..color = Colors.white;
     canvas.drawCircle(pos, 4, corePaint);
     
     // Simple Trail (particles behind)
     final trailPaint = Paint()..color = Colors.cyan.withOpacity(0.5);
     for (int i = 1; i < 10; i++) {
        double trailDist = currentDist - (i * 10); // 10px spacing
        if (trailDist > 0) {
          final trailTangent = metric.getTangentForOffset(trailDist);
          if (trailTangent != null) {
            canvas.drawCircle(trailTangent.position, 4 - (i * 0.3), trailPaint);
          }
        }
     }
   }
  }

  @override
  bool shouldRepaint(covariant _StardustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
