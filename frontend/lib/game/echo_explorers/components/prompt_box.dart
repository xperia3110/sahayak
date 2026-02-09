import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Speech bubble prompt box for showing questions
class PromptBox extends PositionComponent with HasGameRef {
  final String prompt;
  late TextComponent _textComponent;

  PromptBox({required this.prompt});

  @override
  Future<void> onLoad() async {
    // Position at top center with safe margin
    size = Vector2(gameRef.size.x * 0.85, 80);
    anchor = Anchor.topCenter;
    position = Vector2(gameRef.size.x / 2, 100);
    
    // Add styled text
    _textComponent = TextComponent(
      text: 'Find the rhyme for:\n$prompt',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.3,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_textComponent);
    
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    // Draw background box
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    
    // Semi-transparent dark background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.lightGreenAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, borderPaint);
    
    super.render(canvas);
  }
}
