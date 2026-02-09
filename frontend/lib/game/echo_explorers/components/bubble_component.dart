import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Floating bubble component for answer options
class BubbleComponent extends PositionComponent with TapCallbacks, HasGameRef {
  final String text;
  final bool isCorrect;
  final VoidCallback onTap;
  
  late TextComponent _textComponent;
  bool _isPopped = false;
  
  // Bubble colors
  static const Color bubbleColor = Color(0xFF4FC3F7);
  static const Color bubbleDark = Color(0xFF0288D1);

  BubbleComponent({
    required this.text,
    required this.isCorrect,
    required this.onTap,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(130, 70),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Add text
    _textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_textComponent);
    
    // Add floating animation (bobbing up and down)
    final randomOffset = Random().nextDouble() * 0.5;
    add(
      MoveEffect.by(
        Vector2(0, -12),
        EffectController(
          duration: 1.2 + randomOffset,
          alternate: true,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
    
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (_isPopped) return;
    
    // Draw bubble background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    
    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bubbleColor, bubbleDark],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(rrect, paint);
    
    // White border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(rrect, borderPaint);
    
    // Shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.1, size.y * 0.08, size.x * 0.35, size.y * 0.25),
      shinePaint,
    );
    
    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isPopped) return;
    onTap();
  }

  /// Pop the bubble with animation
  Future<void> pop() async {
    _isPopped = true;
    
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.25, curve: Curves.easeIn),
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 250));
    removeFromParent();
  }

  /// Success burst animation
  Future<void> burst() async {
    add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(duration: 0.1),
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 100));
    _isPopped = true;
    
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.15, curve: Curves.easeIn),
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 150));
    removeFromParent();
  }
}
