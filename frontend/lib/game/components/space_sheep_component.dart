import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';

class SpaceSheepComponent extends RiveComponent with HasGameRef {
  final String artboardName;
  final String animationName;

  SpaceSheepComponent({
    required Artboard artboard,
    this.artboardName = 'New Artboard', // Default or check file
    this.animationName = 'Idle', // Default or check file
  }) : super(artboard: artboard, size: Vector2(200, 200));  // Adjust size as needed

  static Future<SpaceSheepComponent> load(String assetName) async {
    final artboard = await loadArtboard(RiveFile.asset(assetName));
    return SpaceSheepComponent(artboard: artboard);
  }

  void speak(String message) {
     // TODO: Implement logic to show text bubble
     // using a child TextComponent or custom overlay
     // For now, we assume simple animation trigger
  }

  void flyAway() {
     // Add MoveEffect to fly out
  }
}
