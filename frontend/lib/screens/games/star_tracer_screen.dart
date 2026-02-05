import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/child.dart';
import '../../game/star_tracer_game.dart';
import 'analysis_report_screen.dart';

class StarTracerScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const StarTracerScreen({super.key, required this.childId, required this.childName});

  @override
  State<StarTracerScreen> createState() => _StarTracerScreenState();
}

class _StarTracerScreenState extends State<StarTracerScreen> {
  bool _isLoading = true;
  int? _sessionId;
  Map<String, dynamic>? _debugMetrics;
  
  // A-Z Logic
  String _currentLetter = 'A';
  final List<String> _letters = ['A', 'B', 'C'];
  int _letterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.token == null) return;

      final sessionData = await ApiService.createSession(
        authProvider.user!.token!,
        widget.childId,
        'StarTracer',
      );
      setState(() {
        _sessionId = sessionData['id'];
        _isLoading = false;
        _currentLetter = _letters[0];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start session: $e')),
      );
      Navigator.pop(context);
    }
  }

  StarTracerGame? _game;
  
  // Store all letter results for final report
  final List<Map<String, dynamic>> _allResults = [];

  Future<void> _handleTraceComplete(List<Map<String, dynamic>> points) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final targetPoints = _game?.getTargetPoints() ?? [];
      final currentLetter = _game?.currentLetter ?? '?';
      
      final results = await ApiService.analyzeStroke(
        authProvider.user!.token!,
        points,
        targetPoints: targetPoints,
      );
      
      if (!mounted) return;
      
      // Store result with letter
      _allResults.add({
        'letter': currentLetter,
        ...results,
      });
      
      setState(() {
        _debugMetrics = results;
      });
      
      // Show Validation Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Good Job! Score: ${results['score'].toStringAsFixed(1)}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );

      // Auto-advance after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _game?.nextLevel();
        setState(() {
            _debugMetrics = null;
        });
      });
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    }
  }
  
  void _handleGameComplete() {
      // Navigate to Analysis Report Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisReportScreen(results: _allResults),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _sessionId == null) {
        return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.cyan))
        );
    }

    _game ??= StarTracerGame(
        onLetterTraceComplete: _handleTraceComplete,
        onGameComplete: _handleGameComplete,
    );

    return Scaffold(
      body: GameWidget<StarTracerGame>(
        game: _game!,
        initialActiveOverlays: const ['HUD'],
        overlayBuilderMap: {
          'HUD': (BuildContext context, StarTracerGame game) {
             return ValueListenableBuilder<bool>(
               valueListenable: game.isUserTurnNotifier,
               builder: (context, isUserTurn, child) {
                 return Stack(
                   children: [
                     // Back Button
                 Positioned(
                   top: 40, 
                   left: 10,
                   child: IconButton(
                     icon: const Icon(Icons.arrow_back, color: Colors.white),
                     onPressed: () => Navigator.pop(context),
                   ), 
                 ),
                 
                 // Metric Overlay (Transient)
                 if (_debugMetrics != null)
                   Positioned(
                     top: 100,
                     right: 20,
                     child: Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.black.withOpacity(0.8),
                         border: Border.all(color: Colors.cyan),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text("Score: ${_debugMetrics!['score']?.toStringAsFixed(1)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                           Text("Accuracy: ${_debugMetrics!['rmse']?.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70)),
                         ],
                       ),
                     ),
                   ),
                   
                 // Submit Button (Bottom Center) - Only show when user's turn
                 if (game.isUserTurn)
                   Positioned(
                     bottom: 40,
                     left: 0,
                     right: 0,
                     child: Center(
                       child: ElevatedButton.icon(
                         onPressed: () {
                           game.submitTrace();
                         },
                         icon: const Icon(Icons.check, color: Colors.black),
                         label: const Text("Done!", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.cyanAccent,
                           padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                         ),
                       ),
                     ),
                     ),
                   ],
                 );
               },
             );
          }
        },
      ),
    );
  }
}
