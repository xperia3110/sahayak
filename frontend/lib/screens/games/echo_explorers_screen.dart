import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../game/echo_explorers/echo_explorers_game.dart';
import 'echo_report_screen.dart';

class EchoExplorersScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const EchoExplorersScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<EchoExplorersScreen> createState() => _EchoExplorersScreenState();
}

class _EchoExplorersScreenState extends State<EchoExplorersScreen> {
  bool _isLoading = true;
  int? _sessionId;
  EchoExplorersGame? _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final sessionData = await ApiService.createSession(
        authProvider.user!.token!,
        widget.childId,
        'echo_explorers',
      );
      final sessionId = sessionData['id'];
      
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _isLoading = false;
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

  void _handleGameComplete(List<QuestionResult> results) async {
    // Convert results to JSON-serializable format
    final resultsJson = results.map((r) => r.toJson()).toList();
    
    // Navigate to report screen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EchoReportScreen(results: resultsJson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _sessionId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A472A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.lightGreen),
              const SizedBox(height: 20),
              Text(
                'Entering the Echo Forest...',
                style: TextStyle(
                  color: Colors.lightGreen[200],
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    _game ??= EchoExplorersGame(onGameComplete: _handleGameComplete);

    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget<EchoExplorersGame>(game: _game!),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
