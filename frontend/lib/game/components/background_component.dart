import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BackgroundComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final Rect rect = Rect.fromLTWH(0, 0, 800, 600);
    final Paint paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
           Color(0xFF2E003E), // Deep Violet
           Colors.black,
        ],
      ).createShader(rect);
      
    canvas.drawRect(rect, paint);
  }
}
