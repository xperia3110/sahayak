import 'dart:math';
import 'package:flame/components.dart';
import 'package:rive/rive.dart';

/// Hero states for state machine control
enum HeroState { idle, talking, success, fail }

/// Echo Hero character - displays just the character
class HeroComponent extends PositionComponent with HasGameRef {
  Artboard? _artboard;
  StateMachineController? _stateMachine;
  
  // State machine inputs
  SMITrigger? _successTrigger;
  SMITrigger? _failTrigger;
  SMIBool? _isTalking;
  SMINumber? _stateInput;
  
  HeroState _currentState = HeroState.idle;
  HeroState get currentState => _currentState;
  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    // Position at bottom center
    final heroSize = Vector2(280, 280);
    size = heroSize;
    anchor = Anchor.bottomCenter;
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 30);

    try {
      // Use RiveFile.asset - it handles initialization automatically
      final riveFile = await RiveFile.asset('assets/rive/echo_rive/echo_hero.riv');
      
      _artboard = riveFile.mainArtboard.instance();
      
      // Try multiple state machine names
      for (final name in ['State Machine 1', 'StateMachine', 'Main', 'Animation']) {
        _stateMachine = StateMachineController.fromArtboard(_artboard!, name);
        if (_stateMachine != null) {
          print('Hero: Found state machine: $name');
          break;
        }
      }
      
      if (_stateMachine != null) {
        _artboard!.addController(_stateMachine!);
        
        // Find inputs
        for (final input in _stateMachine!.inputs) {
          print('Hero input: ${input.name} (${input.runtimeType})');
          final nameLower = input.name.toLowerCase();
          
          if (input is SMITrigger) {
            if (nameLower.contains('success') || nameLower.contains('win') || nameLower.contains('happy')) {
              _successTrigger = input;
            } else if (nameLower.contains('fail') || nameLower.contains('sad') || nameLower.contains('wrong')) {
              _failTrigger = input;
            }
          } else if (input is SMIBool) {
            if (nameLower.contains('talk') || nameLower.contains('speak')) {
              _isTalking = input;
            }
          } else if (input is SMINumber) {
            if (nameLower.contains('state') || nameLower == 'number 1') {
              _stateInput = input;
            }
          }
        }
      } else {
        // Fallback: add first available animation
        print('Hero: No state machine found, trying simple animation');
        for (final animation in riveFile.mainArtboard.animations) {
          print('Hero animation: ${animation.name}');
          _artboard!.addController(SimpleAnimation(animation.name));
          break;
        }
      }
      
      _isLoaded = true;
      print('Hero loaded successfully!');
    } catch (e) {
      print('Failed to load hero Rive: $e');
    }
    
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isLoaded && _artboard != null) {
      _artboard!.advance(dt);
    }
  }

  @override
  void render(canvas) {
    if (!_isLoaded || _artboard == null) return;
    
    canvas.save();
    
    // Scale artboard to fit hero size
    final artboardWidth = _artboard!.width;
    final artboardHeight = _artboard!.height;
    
    final scaleX = size.x / artboardWidth;
    final scaleY = size.y / artboardHeight;
    final scale = min(scaleX, scaleY); // Fit within bounds
    
    // Center the artboard
    final offsetX = (size.x - artboardWidth * scale) / 2;
    final offsetY = (size.y - artboardHeight * scale) / 2;
    
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    
    _artboard!.draw(canvas);
    
    canvas.restore();
  }

  void setState(HeroState state) {
    _currentState = state;
    
    if (_stateInput != null) {
      switch (state) {
        case HeroState.idle:
          _stateInput!.value = 0;
          break;
        case HeroState.talking:
          _stateInput!.value = 1;
          break;
        case HeroState.success:
          _stateInput!.value = 2;
          break;
        case HeroState.fail:
          _stateInput!.value = 3;
          break;
      }
    }
    
    switch (state) {
      case HeroState.idle:
        _isTalking?.value = false;
        break;
      case HeroState.talking:
        _isTalking?.value = true;
        break;
      case HeroState.success:
        _isTalking?.value = false;
        _successTrigger?.fire();
        break;
      case HeroState.fail:
        _isTalking?.value = false;
        _failTrigger?.fire();
        break;
    }
  }

  Future<void> talk({Duration duration = const Duration(seconds: 2)}) async {
    setState(HeroState.talking);
    await Future.delayed(duration);
    setState(HeroState.idle);
  }

  void celebrate() {
    setState(HeroState.success);
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentState == HeroState.success) {
        setState(HeroState.idle);
      }
    });
  }

  void showEncouragement() {
    setState(HeroState.fail);
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentState == HeroState.fail) {
        setState(HeroState.idle);
      }
    });
  }
}
