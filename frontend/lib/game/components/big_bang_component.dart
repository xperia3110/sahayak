import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Big Bang intro effect - Stars appear progressively with a central flash
class BigBangComponent extends PositionComponent {
  final VoidCallback? onComplete;
  final Vector2 screenSize;
  final Random _random = Random();
  
  // Flash effect
  double _flashAlpha = 0.0;
  bool _flashExpanding = true;
  double _flashRadius = 0.0;
  
  // Stars appearing
  final List<_SpawningStar> _spawningStars = [];
  int _starsSpawned = 0;
  final int totalStars = 100;
  double _spawnTimer = 0;
  
  bool _completed = false;
  
  late Vector2 center;

  BigBangComponent({this.onComplete, required this.screenSize});

  @override
  Future<void> onLoad() async {
    center = screenSize / 2;
    // Start with a bright flash
    _flashAlpha = 1.0;
    _flashExpanding = true;
    _flashRadius = 50;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_completed) {
      super.update(dt);
      return;
    }

    // Flash animation
    if (_flashExpanding) {
      _flashRadius += dt * 1000; // Expand fast
      _flashAlpha -= dt * 0.6;
      if (_flashAlpha <= 0) {
        _flashAlpha = 0;
        _flashExpanding = false;
      }
    }

    // Spawn stars progressively
    _spawnTimer += dt;
    if (_starsSpawned < totalStars && _spawnTimer > 0.015) {
      _spawnTimer = 0;
      _spawningStars.add(_SpawningStar(
        position: Vector2(
          center.x + (_random.nextDouble() - 0.5) * screenSize.x * 1.2,
          center.y + (_random.nextDouble() - 0.5) * screenSize.y * 1.2,
        ),
        radius: _random.nextDouble() * 3.0 + 0.5,
        alpha: 0.0,
        targetAlpha: _random.nextDouble() * 0.5 + 0.3,
      ));
      _starsSpawned++;
    }

    // Animate star fade-in
    for (final star in _spawningStars) {
      if (star.alpha < star.targetAlpha) {
        star.alpha += dt * 2.5;
        if (star.alpha > star.targetAlpha) star.alpha = star.targetAlpha;
      }
    }

    // Complete after all stars spawned and flash done
    if (_starsSpawned >= totalStars && !_flashExpanding && _spawningStars.every((s) => s.alpha >= s.targetAlpha * 0.8)) {
      _completed = true;
      onComplete?.call();
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Draw spawned stars
    final paint = Paint();
    for (final star in _spawningStars) {
      paint.color = Colors.white.withOpacity(star.alpha);
      canvas.drawCircle(star.position.toOffset(), star.radius, paint);
    }

    // Draw central flash
    if (_flashAlpha > 0) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(_flashAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _flashRadius / 3);
      canvas.drawCircle(center.toOffset(), _flashRadius, flashPaint);
    }
  }
}

class _SpawningStar {
  Vector2 position;
  double radius;
  double alpha;
  double targetAlpha;
  
  _SpawningStar({
    required this.position,
    required this.radius,
    required this.alpha,
    required this.targetAlpha,
  });
}
