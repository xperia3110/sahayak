import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TrailComponent extends PositionComponent {
  final List<Vector2> points = [];
  
  // Paint objects for "Liquid Light"
  final Paint _corePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round;

  final Paint _glowPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12.0
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

  // Reusing Path object to avoid allocations
  final Path _path = Path();

  @override
  void render(Canvas canvas) {
    if (points.isEmpty) return;

    _path.reset();
    bool needsMoveTo = true;
    
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Check for stroke break marker
      if (point.x < 0 || point.y < 0) {
        needsMoveTo = true; // Next point starts a new stroke
        continue;
      }
      
      if (needsMoveTo) {
        _path.moveTo(point.x, point.y);
        needsMoveTo = false;
      } else {
        _path.lineTo(point.x, point.y);
      }
    }

    // Draw Glow then Core
    canvas.drawPath(_path, _glowPaint);
    canvas.drawPath(_path, _corePaint);
  }

  void addPoint(Vector2 point) {
    points.add(point);
  }

  void clear() {
    points.clear();
  }
}
