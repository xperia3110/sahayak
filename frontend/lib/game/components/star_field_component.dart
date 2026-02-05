import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StarFieldComponent extends PositionComponent with HasGameRef {
  final int starCount;
  final Vector2 screenSize;
  final Random _random = Random();
  late final List<_Star> _stars;
  
  StarFieldComponent({this.starCount = 100, required this.screenSize});

  @override
  Future<void> onLoad() async {
    // Generate random stars across the FULL screen
    _stars = List.generate(starCount, (index) {
      return _Star(
        position: Vector2(
          _random.nextDouble() * screenSize.x,
          _random.nextDouble() * screenSize.y,
        ),
        radius: _random.nextDouble() * 2.5 + 0.5, // 0.5 to 3.0
        alpha: _random.nextDouble() * 0.6 + 0.2, // 0.2 to 0.8
        twinkleSpeed: _random.nextDouble() * 2 + 1, // Twinkle animation speed
        twinkleOffset: _random.nextDouble() * 3.14, // Random phase offset
      );
    });
  }

  @override
  void update(double dt) {
    // Animate star twinkle
    for (final star in _stars) {
      star.twinklePhase += dt * star.twinkleSpeed;
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    
    for (final star in _stars) {
      // Calculate twinkle alpha
      final twinkle = (sin(star.twinklePhase + star.twinkleOffset) + 1) / 2;
      final alpha = star.alpha * (0.5 + 0.5 * twinkle);
      
      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(star.position.toOffset(), star.radius, paint);
      
      // Add glow for larger stars
      if (star.radius > 1.5) {
        paint.color = Colors.white.withOpacity(alpha * 0.3);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(star.position.toOffset(), star.radius * 2, paint);
        paint.maskFilter = null;
      }
    }
  }
}

class _Star {
  final Vector2 position;
  final double radius;
  final double alpha;
  final double twinkleSpeed;
  final double twinkleOffset;
  double twinklePhase = 0;
  
  _Star({
    required this.position, 
    required this.radius, 
    required this.alpha,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}
