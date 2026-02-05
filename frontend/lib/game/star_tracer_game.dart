import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'components/trail_component.dart';
import 'components/letter_guide_component.dart';
import 'components/star_field_component.dart';
import 'components/space_sheep_component.dart';
import 'components/shooting_star_writer.dart';
import 'components/big_bang_component.dart';
import 'components/dialog_box_component.dart';

enum GamePhase { intro, instruction, playing, summary }

class StarTracerGame extends FlameGame with PanDetector {
  // Callbacks
  final Function(List<Map<String, dynamic>>) onLetterTraceComplete;
  final VoidCallback onGameComplete;

  // Screen size (set in onLoad)
  late Vector2 screenSize;
  late Vector2 screenCenter;

  // Components
  late StarFieldComponent _starField;
  SpaceSheepComponent? _spaceSheep;
  late TrailComponent _trail;
  LetterGuideComponent? _currentGuide;
  
  // State
  GamePhase _phase = GamePhase.intro;
  final List<String> _letterDeck = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _sessionLetters = [];
  int _currentLetterIndex = 0;
  
  // ValueNotifier for reactive HUD updates
  final ValueNotifier<bool> isUserTurnNotifier = ValueNotifier<bool>(false);
  bool get _isUserTurn => isUserTurnNotifier.value;
  set _isUserTurn(bool value) => isUserTurnNotifier.value = value;
  
  // Public getter for HUD
  bool get isUserTurn => _isUserTurn;
  
  // Get current letter for display/analysis
  String get currentLetter => _currentLetterIndex < _sessionLetters.length 
      ? _sessionLetters[_currentLetterIndex] 
      : '';
  
  // Get target points for scoring
  List<Map<String, double>> getTargetPoints() {
    if (_currentGuide == null) return [];
    final path = _currentGuide!.getPath();
    final metrics = path.computeMetrics();
    List<Map<String, double>> points = [];
    
    for (final metric in metrics) {
      for (double d = 0; d <= metric.length; d += 10) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) {
          points.add({'x': pos.dx, 'y': pos.dy});
        }
      }
    }
    return points;
  }
  
  // Data Collection
  final List<Map<String, dynamic>> _recordedPoints = [];
  bool _isRecording = false;

  StarTracerGame({
    required this.onLetterTraceComplete,
    required this.onGameComplete,
  });

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    // Use FULL SCREEN resolution
    screenSize = size; // This is the actual screen size from FlameGame
    screenCenter = screenSize / 2;
    
    // Set camera to view the full screen
    camera.viewfinder.anchor = Anchor.topLeft;

    // 1. StarField (covers full screen)
    _starField = StarFieldComponent(starCount: 250, screenSize: screenSize);
    world.add(_starField);

    // 2. Trail
    _trail = TrailComponent();
    world.add(_trail);
    
    // Prepare Random Letters
    _letterDeck.shuffle();
    _sessionLetters.addAll(_letterDeck.take(5));
    
    // Start Sequence
    _startIntro();

    return super.onLoad();
  }

  void _startIntro() {
    _phase = GamePhase.intro;
    
    // Big Bang Animation
    final bigBang = BigBangComponent(
      screenSize: screenSize,
      onComplete: () {
        _startInstruction();
      }
    );
    world.add(bigBang);
  }

  Future<void> _startInstruction() async {
    _phase = GamePhase.instruction;
    
    // Add Sheep
    try {
        _spaceSheep = await SpaceSheepComponent.load('assets/rive/5101-10282-spacesheep.riv');
        if (_spaceSheep != null) {
            _spaceSheep!.size = Vector2(450, 450); // BIGGER sheep!
            _spaceSheep!.anchor = Anchor.center;
            _spaceSheep!.position = Vector2(-200, -200); // Start off-screen
            world.add(_spaceSheep!);

            // 1. Fly In with wobble
            final flyIn = MoveEffect.to(
                screenCenter, 
                EffectController(duration: 2.5, curve: Curves.easeOutBack),
            );
            _spaceSheep!.add(flyIn);
            
            // Add spin during entry
            _spaceSheep!.add(
              RotateEffect.by(
                0.5, // Small rotation
                EffectController(duration: 1.0, alternate: true, repeatCount: 2),
              )
            );

            // 2. After arrival: Float + Pulse + Wobble
            flyIn.onComplete = () {
                // Floating up/down
                _spaceSheep!.add(
                    MoveEffect.by(
                        Vector2(0, -40), 
                        EffectController(duration: 2.0, alternate: true, infinite: true, curve: Curves.easeInOut)
                    )
                );
                
                // Gentle scale pulse (breathing)
                _spaceSheep!.add(
                    ScaleEffect.by(
                        Vector2.all(1.1),
                        EffectController(duration: 1.5, alternate: true, infinite: true, curve: Curves.easeInOut)
                    )
                );
                
                // Subtle rotation wobble
                _spaceSheep!.add(
                    RotateEffect.by(
                        0.1,
                        EffectController(duration: 3.0, alternate: true, infinite: true, curve: Curves.easeInOut)
                    )
                );
                
                _showDialog("Hi! Help me map the stars!\nWatch the Shooting Star!");
            };
        }
    } catch (e) {
        print("Failed to load sheep: $e");
        _startPlaying(); // Continue anyway
    }
  }

  DialogBoxComponent? _dialogBox;
  
  void _showDialog(String message) {
     if (_spaceSheep == null) return;
     
     // Create dialog box in world (not as child of sheep)
     _dialogBox = DialogBoxComponent(
       message: message,
       targetPosition: screenCenter,
     );
     world.add(_dialogBox!);

     // Wait then Exit with style
     Future.delayed(const Duration(seconds: 5), () {
        // Remove dialog box
        if (_dialogBox != null && _dialogBox!.isMounted) {
          world.remove(_dialogBox!);
        }
        
        if (_spaceSheep != null && _spaceSheep!.isMounted) {
            // Spin and fly out
            _spaceSheep!.add(
              RotateEffect.by(
                2.0, // Full spin
                EffectController(duration: 1.5),
              )
            );
            _spaceSheep!.add(
                MoveEffect.to(
                    Vector2(screenSize.x + 300, screenCenter.y),
                    EffectController(duration: 1.5, curve: Curves.easeIn)
                )..onComplete = () {
                   world.remove(_spaceSheep!);
                   _startPlaying();
                }
            );
        } else {
            _startPlaying();
        }
     });
  }

  void _startPlaying() {
    _phase = GamePhase.playing;
    _currentLetterIndex = 0;
    _startLevel(_sessionLetters[_currentLetterIndex]);
  }

  void _startLevel(String letter) {
    _isUserTurn = false;
    _trail.clear();
    _recordedPoints.clear();
    
    // Remove previous guide if any
    if (_currentGuide != null && _currentGuide!.isMounted) {
      world.remove(_currentGuide!);
    }
    
    // Create guide with screen-relative positioning
    _currentGuide = LetterGuideComponent(letter: letter, screenSize: screenSize);
    
    // Writer Animation (Shooting Star)
    ShootingStarWriter? writer;
    writer = ShootingStarWriter(
        path: _currentGuide!.getPath(),
        duration: 3.0,
        onComplete: () {
            // Remove writer trail
            if (writer != null && writer!.isMounted) {
              world.remove(writer!);
            }
            // Add faint guide
            world.add(_currentGuide!);
            _enableUserInteraction();
        }
    );
    world.add(writer);
  }

  void _enableUserInteraction() {
     _isUserTurn = true;
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!_isUserTurn) return;
    _isRecording = true;
    
    final worldPoint = info.eventPosition.global;
    _capturePoint(worldPoint);
    _trail.addPoint(worldPoint);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!_isUserTurn || !_isRecording) return;
    final worldPoint = info.eventPosition.global;
    _capturePoint(worldPoint);
    _trail.addPoint(worldPoint);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (!_isUserTurn || !_isRecording) return;
    _isRecording = false;
    // Add stroke break marker
    _trail.addPoint(Vector2(-1000, -1000));
  }
  
  // Called by HUD Submit button
  void submitTrace() {
    if (_recordedPoints.isEmpty) return;
    _isUserTurn = false;
    onLetterTraceComplete(List.from(_recordedPoints));
  }

  void _capturePoint(Vector2 point) {
    _recordedPoints.add({
      'x': point.x,
      'y': point.y,
      't': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // Called by Screen after analysis success
  void nextLevel() {
    _currentLetterIndex++;
    if (_currentLetterIndex < _sessionLetters.length) {
        _startLevel(_sessionLetters[_currentLetterIndex]);
    } else {
        _phase = GamePhase.summary;
        onGameComplete();
    }
  }
}
