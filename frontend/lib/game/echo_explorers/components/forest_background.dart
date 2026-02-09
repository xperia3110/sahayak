import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:rive/rive.dart';

/// Full-screen animated forest background using Rive
class ForestBackground extends PositionComponent with HasGameRef {
  ForestBackground();

  @override
  Future<void> onLoad() async {
    // Fill entire screen
    size = gameRef.size;
    position = Vector2.zero();
    anchor = Anchor.topLeft;

    // Load the Rive file
    final riveFile = await RiveFile.asset('assets/rive/echo_rive/echo_forest.riv');
    
    // Get the main artboard
    final artboard = riveFile.mainArtboard.instance();
    
    // Try multiple state machine names
    StateMachineController? controller;
    for (final name in ['State Machine 1', 'StateMachine', 'Main', 'Animation']) {
      controller = StateMachineController.fromArtboard(artboard, name);
      if (controller != null) break;
    }
    
    if (controller != null) {
      artboard.addController(controller);
    } else {
      // Fallback: try to find any animation
      for (final animation in riveFile.mainArtboard.animations) {
        final simpleController = SimpleAnimation(animation.name);
        artboard.addController(simpleController);
        break;
      }
    }
    
    // Create Rive component that fills the screen
    final riveComponent = RiveComponent(
      artboard: artboard,
      size: size,
    );
    add(riveComponent);
    
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}
