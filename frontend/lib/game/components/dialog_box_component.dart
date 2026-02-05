import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A speech bubble dialog box component
class DialogBoxComponent extends PositionComponent {
  final String message;
  final Vector2 targetPosition; // Position of who's speaking
  
  late TextPaint _textPaint;
  late Paint _bubblePaint;
  late Paint _borderPaint;
  
  static const double padding = 20;
  static const double borderRadius = 15;
  static const double tailHeight = 20;
  
  DialogBoxComponent({
    required this.message,
    required this.targetPosition,
  });

  @override
  Future<void> onLoad() async {
    _textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
    
    _bubblePaint = Paint()
      ..color = const Color(0xDD000033) // Dark blue semi-transparent
      ..style = PaintingStyle.fill;
      
    _borderPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Position above the target (closer to sheep)
    position = Vector2(targetPosition.x, targetPosition.y - 100);
    anchor = Anchor.bottomCenter;
    
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    // Measure text
    final lines = message.split('\n');
    double maxWidth = 0;
    double totalHeight = 0;
    
    for (final line in lines) {
      final metrics = _textPaint.getLineMetrics(line);
      if (metrics.width > maxWidth) maxWidth = metrics.width;
      totalHeight += metrics.height * 1.3;
    }
    
    final bubbleWidth = maxWidth + padding * 2;
    final bubbleHeight = totalHeight + padding * 2;
    
    // Draw bubble background
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -bubbleHeight / 2 - tailHeight),
        width: bubbleWidth,
        height: bubbleHeight,
      ),
      const Radius.circular(borderRadius),
    );
    
    // Draw tail (triangle pointing down)
    final tailPath = Path()
      ..moveTo(-15, -tailHeight)
      ..lineTo(0, 0)
      ..lineTo(15, -tailHeight)
      ..close();
    
    canvas.drawRRect(bubbleRect, _bubblePaint);
    canvas.drawRRect(bubbleRect, _borderPaint);
    canvas.drawPath(tailPath, _bubblePaint);
    canvas.drawPath(tailPath, _borderPaint);
    
    // Draw text
    double yOffset = -bubbleHeight - tailHeight + padding;
    for (final line in lines) {
      _textPaint.render(
        canvas, 
        line, 
        Vector2(-maxWidth / 2, yOffset),
      );
      yOffset += 30;
    }
  }
}
