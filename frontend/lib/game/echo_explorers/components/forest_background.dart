import 'dart:math';
import 'package:flame/components.dart';
import 'package:rive/rive.dart';

/// Full-screen animated forest background using Rive
class ForestBackground extends PositionComponent with HasGameRef {
  Artboard? _artboard;
  SMINumber? _xAxis;
  SMINumber? _yAxis;
  SMIBool? _isShaking;
  SMITrigger? _isBirdTouched;
  
  double _time = 0;
  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    position = Vector2.zero();
    anchor = Anchor.topLeft;

    try {
      // Use RiveFile.asset - it handles initialization automatically
      final riveFile = await RiveFile.asset('assets/rive/echo_rive/echo_forest.riv');
      
      _artboard = riveFile.mainArtboard.instance();
      
      // Get state machine
      StateMachineController? controller;
      for (final name in ['State Machine 1', 'StateMachine', 'Main']) {
        controller = StateMachineController.fromArtboard(_artboard!, name);
        if (controller != null) {
          print('Forest: Found state machine: $name');
          break;
        }
      }
      
      if (controller != null) {
        _artboard!.addController(controller);
        
        // Get the specific inputs
        for (final input in controller.inputs) {
          print('Forest input: ${input.name} (${input.runtimeType})');
          switch (input.name) {
            case 'xAxis':
              _xAxis = input as SMINumber;
              break;
            case 'yAxis':
              _yAxis = input as SMINumber;
              break;
            case 'isShaking':
              _isShaking = input as SMIBool;
              _isShaking?.value = true;
              break;
            case 'isBirdTouched':
              _isBirdTouched = input as SMITrigger;
              break;
          }
        }
      } else {
        // Try simple animation
        print('Forest: No state machine found, trying simple animation');
        for (final anim in riveFile.mainArtboard.animations) {
          print('Forest animation: ${anim.name}');
          _artboard!.addController(SimpleAnimation(anim.name));
          break;
        }
      }
      
      _isLoaded = true;
      print('Forest loaded successfully!');
    } catch (e) {
      print('Failed to load forest Rive: $e');
    }
    
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isLoaded || _artboard == null) return;
    
    // Advance the artboard
    _artboard!.advance(dt);
    
    // Animate the parallax effect
    _time += dt;
    
    if (_xAxis != null) {
      _xAxis!.value = sin(_time * 0.5) * 15;
    }
    if (_yAxis != null) {
      _yAxis!.value = sin(_time * 0.3) * 8;
    }
  }

  @override
  void render(canvas) {
    if (!_isLoaded || _artboard == null) return;
    
    canvas.save();
    
    // Scale artboard to fill screen
    final artboardWidth = _artboard!.width;
    final artboardHeight = _artboard!.height;
    
    final scaleX = size.x / artboardWidth;
    final scaleY = size.y / artboardHeight;
    final scale = max(scaleX, scaleY); // Cover entire screen
    
    // Center the artboard
    final offsetX = (size.x - artboardWidth * scale) / 2;
    final offsetY = (size.y - artboardHeight * scale) / 2;
    
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    
    _artboard!.draw(canvas);
    
    canvas.restore();
  }

  void touchBird() {
    _isBirdTouched?.fire();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }
}
