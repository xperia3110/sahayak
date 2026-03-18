
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../screens/games/monster_munch/services/monster_audio_service.dart';
import '../../../../screens/games/monster_munch/widgets/animated_background.dart';
import '../../../../screens/games/monster_munch/widgets/monster_widget.dart';
import '../../../../screens/games/monster_munch/models/monster_game_result.dart';

class ComparisonScreen extends StatefulWidget {
  final int childId;
  const ComparisonScreen({super.key, required this.childId});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final Random _random = Random();
  int _leftValue = 0;
  int _rightValue = 0;
  MonsterState _monsterState = MonsterState.idle;
  int _round = 0;
  final int _totalRounds = 10;
  DateTime? _shownTime;
  int _score = 0;
  int _streak = 0;

  // Session Data
  List<MonsterGameResult> _results = [];
  int? _sessionId;
  bool _isSubmitting = false;

  // Food emojis
  final List<String> _foodEmojis = ['🍓', '🍌', '🍊', '🥕', '🍇', '🍉', '🥦', '🌽'];
  String _currentFood = '🍓';

  @override
  void initState() {
    super.initState();
    MonsterAudioService().playRoar();
    _startSession();
    _startRound();
  }

  Future<void> _startSession() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final sessionData = await ApiService.createSession(
        authProvider.user!.token!,
        widget.childId,
        'monster_munch_comparison',
      );
      _sessionId = sessionData['id'];
    } catch (e) {
      print("Error creating session: $e");
    }
  }

  void _startRound() {
    if (_round >= _totalRounds) {
      _showGameOver();
      return;
    }

    setState(() {
      _round++;
      _monsterState = MonsterState.idle;
      _generateValues();
      _shownTime = DateTime.now();
      _currentFood = _foodEmojis[_random.nextInt(_foodEmojis.length)];
    });
  }

  void _generateValues() {
    bool useHighRatio = _random.nextBool();
    int base = _random.nextInt(5) + 3;
    int diff;
    
    // Dyscalculia screening: test close numbers (low ratio) vs far numbers (high ratio)
    if (useHighRatio) {
      diff = _random.nextInt(3) + 3; // e.g., base 4, diff 5 -> 4 vs 9
    } else {
      diff = _random.nextInt(2) + 1; // e.g., base 4, diff 1 -> 4 vs 5
    }
    
    if (_random.nextBool()) {
      _leftValue = base;
      _rightValue = base + diff;
    } else {
      _leftValue = base + diff;
      _rightValue = base;
    }
    
    if (_leftValue > 15) _leftValue = 15;
    if (_rightValue > 15) _rightValue = 15;
    if (_leftValue == _rightValue) _rightValue++;
  }

  void _handleSelection(int selectedValue, int otherValue) {
    bool isCorrect = selectedValue > otherValue;
    
    int distance = (selectedValue - otherValue).abs();
    double ratio = selectedValue > otherValue 
        ? selectedValue / otherValue 
        : otherValue / selectedValue;
    String ratioType = ratio > 1.5 ? 'high' : 'low';
    
    final now = DateTime.now();
    final rt = now.difference(_shownTime!).inMilliseconds;

    final result = MonsterGameResult(
      id: const Uuid().v4(),
      gameMode: MonsterGameMode.comparison,
      timestamp: now.millisecondsSinceEpoch,
      reactionTimeMs: rt,
      isCorrect: isCorrect,
      leftValue: _leftValue,
      rightValue: _rightValue,
      distance: distance,
      ratioType: ratioType,
      userAnswer: selectedValue,
    );
    _results.add(result);

    setState(() {
      if (isCorrect) {
        _score += 10;
        _streak++;
        MonsterAudioService().playCorrect();
        _monsterState = MonsterState.happy;
        if (_streak >= 3) MonsterAudioService().playRoar();
      } else {
        _streak = 0;
        MonsterAudioService().playWrong();
        _monsterState = MonsterState.sad;
      }
    });

    Future.delayed(const Duration(seconds: 2), _startRound);
  }

  void _showGameOver() async {
    setState(() {
      _monsterState = MonsterState.celebrate;
    });
    MonsterAudioService().playCelebrate();

    await _submitResults();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 Awesome!', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $_score', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            Text('You finished the Snack Battle!', style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Menu'),
          )
        ],
      ),
    );
  }

  Future<void> _submitResults() async {
     setState(() => _isSubmitting = true);
     try {
       final auth = context.read<AuthProvider>();
       await ApiService.analyzeDyscalculia(
         auth.user!.token!,
         _sessionId!,
         _results.map((r) => r.toJson()).toList(),
       );
     } catch (e) {
       print("Error submitting results: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving results: $e")));
       }
     } finally {
       if (mounted) setState(() => _isSubmitting = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            // Score Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          'Round $_round/$_totalRounds',
                          style: GoogleFonts.comicNeue(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Score: $_score',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '🔥 $_streak',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                  ],
                ),
              ),
            ),
            
            Padding(
               padding: const EdgeInsets.all(10.0),
               child: MonsterWidget(state: _monsterState),
            ),
            Text(
              'Tap the side with MORE!',
              style: GoogleFonts.comicNeue(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSide(_leftValue, _rightValue),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildSide(_rightValue, _leftValue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSide(int value, int otherValue) {
    return InkWell(
      onTap: () => _handleSelection(value, otherValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade300, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(value, (index) {
            return Text(
              _currentFood,
              style: const TextStyle(fontSize: 45),
            );
          }),
        ),
      ),
    );
  }
}
