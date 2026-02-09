import 'package:flame/components.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:rive/rive.dart';

/// Hero states for state machine control
enum HeroState { idle, talking, success, fail }

/// Echo Hero character with state machine management
class HeroComponent extends PositionComponent with HasGameRef {
  RiveComponent? _riveComponent;
  StateMachineController? _stateMachine;
  
  // State machine inputs - try various common names
  SMITrigger? _successTrigger;
  SMITrigger? _failTrigger;
  SMIBool? _isTalking;
  SMINumber? _stateInput;
  
  HeroState _currentState = HeroState.idle;
  HeroState get currentState => _currentState;

  @override
  Future<void> onLoad() async {
    // Position at bottom center, larger size
    final heroSize = Vector2(300, 300);
    size = heroSize;
    anchor = Anchor.bottomCenter;
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 20);

    // Load Rive file
    final riveFile = await RiveFile.asset('assets/rive/echo_rive/echo_hero.riv');
    final artboard = riveFile.mainArtboard.instance();
    
    // Try multiple state machine names
    for (final name in ['State Machine 1', 'StateMachine', 'Main', 'Animation']) {
      _stateMachine = StateMachineController.fromArtboard(artboard, name);
      if (_stateMachine != null) break;
    }
    
    if (_stateMachine != null) {
      artboard.addController(_stateMachine!);
      
      // Find inputs by various common names
      for (final input in _stateMachine!.inputs) {
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
      for (final animation in riveFile.mainArtboard.animations) {
        artboard.addController(SimpleAnimation(animation.name));
        break;
      }
    }
    
    _riveComponent = RiveComponent(
      artboard: artboard,
      size: heroSize,
    );
    add(_riveComponent!);
    
    await super.onLoad();
  }

  /// Switch the hero to a specific state
  void setState(HeroState state) {
    _currentState = state;
    
    // Try using number input if available
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
    
    // Also try bool/trigger inputs
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

  /// Play talking animation for a duration
  Future<void> talk({Duration duration = const Duration(seconds: 2)}) async {
    setState(HeroState.talking);
    await Future.delayed(duration);
    setState(HeroState.idle);
  }

  /// Play success animation
  void celebrate() {
    setState(HeroState.success);
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentState == HeroState.success) {
        setState(HeroState.idle);
      }
    });
  }

  /// Play fail animation
  void showEncouragement() {
    setState(HeroState.fail);
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentState == HeroState.fail) {
        setState(HeroState.idle);
      }
    });
  }
}
