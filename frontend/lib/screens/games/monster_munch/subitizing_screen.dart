
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

class SubitizingScreen extends StatefulWidget {
  final int childId;
  const SubitizingScreen({super.key, required this.childId});

  @override
  State<SubitizingScreen> createState() => _SubitizingScreenState();
}

class _SubitizingScreenState extends State<SubitizingScreen> {
  final Random _random = Random();
  int _currentValue = 0;
  bool _showingSnacks = false;
  bool _showingInput = false;
  MonsterState _monsterState = MonsterState.idle;
  int _round = 0;
  final int _totalRounds = 10;
  DateTime? _inputShownTime;
  int _score = 0;
  int _streak = 0;

  // Session Data
  List<MonsterGameResult> _results = [];
  int? _sessionId;
  bool _isSubmitting = false;

  // Food emojis for variety
  final List<String> _foodEmojis = ['🍪', '🍎', '🍰', '🍩', '🍕', '🍔', '🌮', '🍇'];
  String _currentFood = '🍪';

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
        'monster_munch_subitizing',
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
      _showingSnacks = false;
      _showingInput = false;
      _currentValue = _random.nextInt(9) + 1;
      _currentFood = _foodEmojis[_random.nextInt(_foodEmojis.length)];
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _showingSnacks = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _showingSnacks = false;
          _showingInput = true;
          _inputShownTime = DateTime.now();
        });
      });
    });
  }

  void _handleInput(int value) {
    if (!_showingInput) return;
    
    final now = DateTime.now();
    final rt = now.difference(_inputShownTime!).inMilliseconds;
    final isCorrect = value == _currentValue;

    final result = MonsterGameResult(
      id: const Uuid().v4(),
      gameMode: MonsterGameMode.subitizing,
      timestamp: now.millisecondsSinceEpoch,
      reactionTimeMs: rt,
      isCorrect: isCorrect,
      itemsShown: _currentValue,
      userAnswer: value,
    );
    _results.add(result);

    setState(() {
      _showingInput = false;
      if (isCorrect) {
        _score += 10;
        _streak++;
        MonsterAudioService().playCorrect();
        if (rt < 2000) {
          _monsterState = MonsterState.happy;
          if (_streak >= 3) MonsterAudioService().playRoar(); 
        } else {
          _monsterState = MonsterState.eat;
          MonsterAudioService().playEat();
        }
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
        title: Text('🎉 Great Job!', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold, fontSize: 28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $_score', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 10),
            Text('You finished all rounds!', style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to menu
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
                          color: Colors.orange,
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
            
            // Monster Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: MonsterWidget(state: _monsterState),
            ),
            
            Expanded(
              child: Center(
                child: _showingSnacks
                    ? _buildSnacks()
                    : _showingInput
                        ? _buildNumberPad()
                        : const SizedBox(), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnacks() {
    return Container(
      width: 320,
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))]
      ),
      child: Center(
        child: Wrap(
          spacing: 15,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: List.generate(_currentValue, (index) {
             return Text(
               _currentFood,
               style: const TextStyle(fontSize: 50),
             );
          }),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: List.generate(9, (index) {
          final num = index + 1;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: Colors.orange.shade200,
            ),
            onPressed: () => _handleInput(num),
            child: Text(
              '$num',
              style: GoogleFonts.comicNeue(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          );
        }),
      ),
    );
  }
}
