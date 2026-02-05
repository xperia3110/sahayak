import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Shooting Star that progressively draws a letter path
/// The path is revealed as the star moves, NOT shown beforehand
class ShootingStarWriter extends PositionComponent {
  final Path path;
  final double duration;
  final VoidCallback? onComplete;
  
  // Visuals - Star Head (Glowing)
  final Paint _starCorePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
    
  final Paint _starGlowPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

  // Trail Paint (Faint, revealed progressively)
  final Paint _trailPaint = Paint()
    ..color = Colors.white.withOpacity(0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round;

  double _progress = 0;
  bool _animating = false;
  bool _completed = false;
  
  // Cached path metrics for multi-contour support
  late List<PathMetric> _metrics;
  late double _totalLength;

  ShootingStarWriter({
    required this.path, 
    this.duration = 3.0,
    this.onComplete,
  });

  @override
  Future<void> onLoad() async {
    // Pre-compute all path metrics
    _metrics = path.computeMetrics().toList();
    _totalLength = _metrics.fold(0.0, (sum, m) => sum + m.length);
    
    // Auto-start the animation
    start();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_animating && !_completed) {
      _progress += dt / duration;
      if (_progress >= 1.0) {
        _progress = 1.0;
        _animating = false;
        _completed = true;
        onComplete?.call();
      }
    }
    super.update(dt);
  }

  void start() {
    _progress = 0;
    _animating = true;
    _completed = false;
  }

  @override
  void render(Canvas canvas) {
    if (_metrics.isEmpty) return;

    final targetDist = _totalLength * _progress;
    double accumulatedDist = 0;
    Offset? starPosition;

    // Draw each contour up to the current progress
    for (final metric in _metrics) {
      final contourEnd = accumulatedDist + metric.length;
      
      if (targetDist >= contourEnd) {
        // This entire contour is already traced
        canvas.drawPath(metric.extractPath(0, metric.length), _trailPaint);
        accumulatedDist = contourEnd;
      } else if (targetDist > accumulatedDist) {
        // We're in the middle of this contour
        final localDist = targetDist - accumulatedDist;
        canvas.drawPath(metric.extractPath(0, localDist), _trailPaint);
        
        // Get star position
        final tangent = metric.getTangentForOffset(localDist);
        if (tangent != null) {
          starPosition = tangent.position;
        }
        break; // Don't process further contours yet
      } else {
        // Haven't reached this contour yet
        break;
      }
    }

    // Draw Shooting Star Head with glow
    if (starPosition != null) {
      // Outer glow
      canvas.drawCircle(starPosition, 18.0, _starGlowPaint);
      // Core
      canvas.drawCircle(starPosition, 8.0, _starCorePaint);
      
      // Sparkle effect (small dots trailing)
      for (int i = 1; i <= 5; i++) {
        final sparkleOffset = Offset(
          starPosition.dx - (i * 8),
          starPosition.dy + (i % 2 == 0 ? 4 : -4)
        );
        canvas.drawCircle(
          sparkleOffset, 
          3.0 - (i * 0.4), 
          Paint()..color = Colors.white.withOpacity(0.6 - (i * 0.1))
        );
      }
    }
  }
}
