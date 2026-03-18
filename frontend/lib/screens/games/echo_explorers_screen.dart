import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'echo_report_screen.dart';
import '../../game/echo_explorers/data/question_bank.dart'; 

class EchoExplorersScreen extends StatefulWidget {
  final int childId;

  const EchoExplorersScreen({super.key, required this.childId});

  @override
  State<EchoExplorersScreen> createState() => _EchoExplorersScreenState();
}

class _EchoExplorersScreenState extends State<EchoExplorersScreen> with SingleTickerProviderStateMixin {
  // Game State
  int? _sessionId;
  bool _isLoading = true;
  String? _error;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  List<QuestionResult> _results = [];
  bool _showingFeedback = false;
  List<String> _currentOptions = [];
  
  // Timing
  DateTime? _questionStartTime;

  // TTS
  final FlutterTts _tts = FlutterTts();

  // Rive Forest
  rive.Artboard? _forestArtboard;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _loadGame();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.1);
  }

  Future<void> _loadGame() async {
    try {
      await _loadRiveFiles();
      await _startSession();
      
      // Load questions
      _questions = QuestionBank.getRandomQuestions(5);
      
      if (mounted) {
        setState(() => _isLoading = false);
        _startQuestion();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadRiveFiles() async {
    try {
      // --- Forest Only ---
      final forestFile = await rive.RiveFile.asset('assets/rive/echo_rive/echo_forest.riv');
      // Try to find 'forest.svg' or fallback
      var forestArtboard = forestFile.artboardByName('forest.svg') ?? 
                           forestFile.artboards.firstWhere(
                             (a) => a.name.toLowerCase().contains('forest'),
                             orElse: () => forestFile.mainArtboard
                           ).instance();
      
      forestArtboard = forestArtboard.instance();
      // Add controller
      bool forestAdded = false;
      for (final name in ['State Machine 1', 'Main', 'main']) {
         try {
           final controller = rive.StateMachineController.fromArtboard(forestArtboard, name);
           if (controller != null) {
             forestArtboard.addController(controller);
             forestAdded = true;
             controller.findInput<bool>('isShaking')?.value = true;
             break;
           }
         } catch (_) {}
      }
      if (!forestAdded && forestArtboard.animations.isNotEmpty) {
        forestArtboard.addController(rive.SimpleAnimation(forestArtboard.animations.first.name));
      }

      setState(() {
        _forestArtboard = forestArtboard;
      });
    } catch (e) {
      print("Rive Load Error: $e");
    }
  }

  Future<void> _startSession() async {
    final authProvider = context.read<AuthProvider>();
    final sessionData = await ApiService.createSession(
      authProvider.user!.token!,
      widget.childId,
      'echo_explorers',
    );
    _sessionId = sessionData['id'];
  }

  void _startQuestion() async {
    if (_currentQuestionIndex >= _questions.length) {
      _finishGame();
      return;
    }

    _showingFeedback = false;
    final q = _questions[_currentQuestionIndex];
    _questionStartTime = DateTime.now();

    // Shuffle options for this question
    _currentOptions = List.from(q.options)..shuffle();
    
    setState(() {});
    
    // Speak
    await _tts.speak("Find the rhyme for ${q.prompt}");
  }

  void _handleAnswer(String answer) async {
    if (_showingFeedback) return;
    _showingFeedback = true;

    final q = _questions[_currentQuestionIndex];
    final isCorrect = answer == q.correctAnswer;
    final reactionTime = DateTime.now().difference(_questionStartTime!).inMilliseconds;

    // Record result
    _results.add(QuestionResult(
      questionId: q.id,
      prompt: q.prompt,
      options: q.options,
      userAnswer: answer,
      isCorrect: isCorrect,
      reactionTimeMs: reactionTime,
    ));

    // Feedback
    await _tts.speak(isCorrect ? "Great job!" : "Nice try!");
    
    // UI update for feedback colors is handled by _showingFeedback + build method

    // Next
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentQuestionIndex++;
        });
        _startQuestion();
      }
    });
  }

  void _finishGame() async {
      if (_sessionId == null) return;
      
      final authProvider = context.read<AuthProvider>();
      try {
         await ApiService.analyzeDyslexia(
           authProvider.user!.token!, 
           _sessionId!,
           _results.map((r) => r.toJson()).toList()
         );
         if(mounted) {
           Navigator.pushReplacement(context, MaterialPageRoute(
             builder: (_) => EchoReportScreen(results: _results.map((r) => r.toJson()).toList())
           ));
         }
      } catch (e) {
         if(mounted) {
           Navigator.pushReplacement(context, MaterialPageRoute(
             builder: (_) => EchoReportScreen(results: _results.map((r) => r.toJson()).toList())
           ));
         }
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    
    final currentQ = _currentQuestionIndex < _questions.length ? _questions[_currentQuestionIndex] : null;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Forest Background
          if (_forestArtboard != null)
            Positioned.fill(
              child: rive.Rive(artboard: _forestArtboard!, fit: BoxFit.cover),
            )
          else 
            Container(color: Colors.green.shade900),

          // 2. UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_currentQuestionIndex + 1} / ${_questions.length}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),

                // Prompt Box (Signboard style)
                if (currentQ != null)
                  _buildPromptSign(currentQ.prompt),

                const SizedBox(height: 40),

                // Answer Options (Static Wrap with shuffled options)
                if (currentQ != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: _currentOptions.map((opt) => _buildStaticOption(opt, currentQ.correctAnswer)).toList(),
                    ),
                  ),

                const Spacer(flex: 2),

                // Back Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white24,
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSign(String text) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037), // Dark wood color
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8D6E63), width: 4), // Lighter wood border
        boxShadow: [
          const BoxShadow(color: Colors.black38, offset: Offset(0,4), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "FIND RHYME FOR", 
            style: TextStyle(
              color: Color(0xFFD7CCC8), // Light wood text
              fontSize: 12, 
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 5),
          Text(
            text, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 36, 
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1))]
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStaticOption(String text, String correctAnswer) {
    return GestureDetector(
      onTap: () => _handleAnswer(text),
      child: Container(
        width: 140,
        height: 80, // Fixed size for consistency
        decoration: BoxDecoration(
          color: _showingFeedback 
             ? (text == correctAnswer 
                 ? Colors.green.shade600 
                 : Colors.grey.shade400)
             : Colors.blue.shade400,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: Colors.black26, offset: Offset(0,4), blurRadius: 2),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black45)]
          ),
        ),
      ),
    );
  }
}

// Result class
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
