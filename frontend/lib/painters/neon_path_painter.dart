import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class NeonPathPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  NeonPathPainter({
    required this.points,
    this.color = Colors.cyan,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 1. Core Stroke (White/Bright)
    final Paint corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * 0.4
      ..style = PaintingStyle.stroke;

    // 2. Glow Stroke (Main Color)
    final Paint glowPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0); // Soft neon glow

    // 3. Ambient Glow (Faint outer ring)
    final Paint ambientPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth * 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0); // Large blur

    final Path path = Path();
    bool isFirst = true;

    for (int i = 0; i < points.length; i++) {
      if (points[i] == null) {
        isFirst = true;
        continue;
      }
      
      if (isFirst) {
        path.moveTo(points[i]!.dx, points[i]!.dy);
        isFirst = false;
      } else {
        // Simple smoothing could go here, but raw for now to reflect jitter
        path.lineTo(points[i]!.dx, points[i]!.dy);
      }
    }

    // Draw layers from bottom up
    canvas.drawPath(path, ambientPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant NeonPathPainter oldDelegate) {
    return true; // Always repaint for live drawing
  }
}
