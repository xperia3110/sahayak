import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LetterGuideComponent extends PositionComponent {
  final String letter;
  final Vector2 screenSize;
  final Path _path = Path();
  
  late Vector2 center;
  late double letterScale; // Renamed to avoid conflict with PositionComponent.scale
  
  final Paint _guidePaint = Paint()
    ..color = Colors.white.withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20.0
    ..strokeCap = StrokeCap.round;

  final Paint _dashedPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
      
  LetterGuideComponent({required this.letter, required this.screenSize}) {
    // Calculate center and scale based on screen size
    center = screenSize / 2;
    letterScale = min(screenSize.x, screenSize.y) / 600; // Base scale factor
    _generatePath();
  }

  double min(double a, double b) => a < b ? a : b;

  @override
  Future<void> onLoad() async {
    return super.onLoad();
  }

  void _generatePath() {
    _path.reset();
    
    // Letter dimensions relative to center
    final double letterHeight = 400 * letterScale;
    final double letterWidth = 300 * letterScale;
    
    final double top = center.y - letterHeight / 2;
    final double bottom = center.y + letterHeight / 2;
    final double left = center.x - letterWidth / 2;
    final double right = center.x + letterWidth / 2;
    final double midY = center.y;
    
    switch (letter) {
      case 'A':
        _path.moveTo(center.x, top);
        _path.lineTo(left, bottom);
        _path.moveTo(center.x, top);
        _path.lineTo(right, bottom);
        _path.moveTo(left + letterWidth * 0.2, midY + letterHeight * 0.1);
        _path.lineTo(right - letterWidth * 0.2, midY + letterHeight * 0.1);
        break;
      case 'B':
        _path.moveTo(left, top);
        _path.lineTo(left, bottom);
        _path.moveTo(left, top);
        _path.quadraticBezierTo(right, top, right, midY - letterHeight * 0.15);
        _path.quadraticBezierTo(right, midY, left, midY);
        _path.moveTo(left, midY);
        _path.quadraticBezierTo(right + letterWidth * 0.1, midY, right + letterWidth * 0.1, midY + letterHeight * 0.2);
        _path.quadraticBezierTo(right + letterWidth * 0.1, bottom, left, bottom);
        break;
      case 'C':
        _path.moveTo(right, top + letterHeight * 0.15);
        _path.quadraticBezierTo(left - letterWidth * 0.2, top, left, midY);
        _path.quadraticBezierTo(left - letterWidth * 0.2, bottom, right, bottom - letterHeight * 0.15);
        break;
      case 'D':
        _path.moveTo(left, top);
        _path.lineTo(left, bottom);
        _path.moveTo(left, top);
        _path.cubicTo(right + letterWidth * 0.3, top, right + letterWidth * 0.3, bottom, left, bottom);
        break;
      case 'E':
        _path.moveTo(right, top);
        _path.lineTo(left, top);
        _path.lineTo(left, bottom);
        _path.lineTo(right, bottom);
        _path.moveTo(left, midY);
        _path.lineTo(right - letterWidth * 0.2, midY);
        break;
      default:
        // Fallback Circle
        _path.addOval(Rect.fromCircle(center: center.toOffset(), radius: 150 * letterScale));
    }
  }

  Path getPath() => _path;

  @override
  void render(Canvas canvas) {
    // Draw broad faint guide
    canvas.drawPath(_path, _guidePaint);
    
    // Draw dashed "ghost path" on top
    canvas.drawPath(_path, _dashedPaint);
  }
}
