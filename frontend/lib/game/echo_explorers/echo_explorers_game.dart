import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'components/forest_background.dart';
import 'components/hero_component.dart';
import 'components/bubble_component.dart';
import 'components/prompt_box.dart';
import 'data/question_bank.dart';

/// Game phase states
enum EchoGamePhase { intro, question, waitingForAnswer, feedback, complete }

/// Result data for each question
class QuestionResult {
  final String questionId;
  final String prompt;
  final List<String> options;
  final String userAnswer;
  final bool isCorrect;
  final int reactionTimeMs;

  QuestionResult({
    required this.questionId,
    required this.prompt,
    required this.options,
    required this.userAnswer,
    required this.isCorrect,
    required this.reactionTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'prompt': prompt,
    'options': options,
    'user_answer': userAnswer,
    'is_correct': isCorrect,
    'reaction_time_ms': reactionTimeMs,
  };
}

/// Main Echo Explorers game class
class EchoExplorersGame extends FlameGame {
  // Callbacks
  final Function(List<QuestionResult>) onGameComplete;

  // Components
  ForestBackground? _forest;
  HeroComponent? _hero;
  PromptBox? _promptBox;
  final List<BubbleComponent> _bubbles = [];

  // Game state
  EchoGamePhase _phase = EchoGamePhase.intro;
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  final List<QuestionResult> _results = [];
  
  // Timing
  DateTime? _questionStartTime;
  
  // Current question
  Question get currentQuestion => _questions[_currentQuestionIndex];

  EchoExplorersGame({required this.onGameComplete});

  @override
  Color backgroundColor() => const Color(0xFF1A472A); // Deep forest green

  @override
  Future<void> onLoad() async {
    // Initialize questions (5 random from bank)
    _questions = QuestionBank.getRandomQuestions(5);

    // Layer 1: Forest Background (fills entire screen)
    _forest = ForestBackground();
    await add(_forest!);

    // Layer 2: Hero Character (bottom center)
    _hero = HeroComponent();
    await add(_hero!);

    // Brief delay then start
    await Future.delayed(const Duration(milliseconds: 500));
    _startIntro();

    await super.onLoad();
  }

  void _startIntro() {
    _phase = EchoGamePhase.intro;
    
    // Start first question after brief intro
    Future.delayed(const Duration(seconds: 1), () {
      _showQuestion();
    });
  }

  void _showQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _completeGame();
      return;
    }

    _phase = EchoGamePhase.question;
    final question = currentQuestion;

    // Remove old prompt box if exists
    _promptBox?.removeFromParent();

    // Create new prompt box
    _promptBox = PromptBox(prompt: question.prompt);
    add(_promptBox!);

    // Hero talks
    _hero?.talk(duration: const Duration(seconds: 2));

    // Spawn bubbles after hero talks
    Future.delayed(const Duration(milliseconds: 1500), () {
      _spawnBubbles(question);
    });
  }

  void _spawnBubbles(Question question) {
    _phase = EchoGamePhase.waitingForAnswer;
    _questionStartTime = DateTime.now();

    // Clear existing bubbles
    for (final bubble in _bubbles) {
      if (bubble.isMounted) bubble.removeFromParent();
    }
    _bubbles.clear();

    // Shuffle options
    final shuffledOptions = List<String>.from(question.options)..shuffle();
    
    // Calculate bubble positions in middle area of screen
    // Area between prompt box (y=180) and hero (y starts around screenHeight - 300)
    final screenWidth = size.x;
    final screenHeight = size.y;
    
    // Bubble area: from y=200 to y=screenHeight - 350
    final bubbleAreaTop = 220.0;
    final bubbleAreaBottom = screenHeight - 380;
    final bubbleAreaHeight = bubbleAreaBottom - bubbleAreaTop;
    
    // Create 3 bubbles in a nice spread
    final positions = [
      Vector2(screenWidth * 0.25, bubbleAreaTop + bubbleAreaHeight * 0.2),
      Vector2(screenWidth * 0.75, bubbleAreaTop + bubbleAreaHeight * 0.35),
      Vector2(screenWidth * 0.5, bubbleAreaTop + bubbleAreaHeight * 0.65),
    ];

    // Shuffle positions for variety
    positions.shuffle(Random());

    for (int i = 0; i < shuffledOptions.length && i < positions.length; i++) {
      final option = shuffledOptions[i];
      final isCorrect = option == question.correctAnswer;
      
      final bubble = BubbleComponent(
        text: option,
        isCorrect: isCorrect,
        position: positions[i],
        onTap: () => _handleBubbleTap(option, isCorrect),
      );
      
      _bubbles.add(bubble);
      add(bubble);
    }
  }

  void _handleBubbleTap(String answer, bool isCorrect) {
    if (_phase != EchoGamePhase.waitingForAnswer) return;
    
    _phase = EchoGamePhase.feedback;
    
    // Calculate reaction time
    final reactionTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 0;

    // Record result
    _results.add(QuestionResult(
      questionId: currentQuestion.id,
      prompt: currentQuestion.prompt,
      options: currentQuestion.options,
      userAnswer: answer,
      isCorrect: isCorrect,
      reactionTimeMs: reactionTime,
    ));

    // Pop all bubbles
    for (final bubble in _bubbles) {
      if (bubble.text == answer) {
        if (isCorrect) {
          bubble.burst();
        } else {
          bubble.pop();
        }
      } else {
        bubble.pop();
      }
    }

    // Remove prompt box
    _promptBox?.removeFromParent();
    _promptBox = null;

    // Hero reaction
    if (isCorrect) {
      _hero?.celebrate();
    } else {
      _hero?.showEncouragement();
    }

    // Next question after delay
    Future.delayed(const Duration(seconds: 2), () {
      _currentQuestionIndex++;
      _showQuestion();
    });
  }

  void _completeGame() {
    _phase = EchoGamePhase.complete;
    
    // Remove prompt if still there
    _promptBox?.removeFromParent();
    
    // Show completion message
    final completeText = TextComponent(
      text: 'Great Job, Explorer!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 6, offset: Offset(3, 3)),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 3),
    );
    add(completeText);

    _hero?.celebrate();

    // Callback with results
    Future.delayed(const Duration(seconds: 2), () {
      onGameComplete(_results);
    });
  }

  /// Get current results for external access
  List<QuestionResult> get results => List.unmodifiable(_results);
}
