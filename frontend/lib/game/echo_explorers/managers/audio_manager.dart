import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Audio manager for Echo Explorers
/// Handles TTS for questions and sound effects
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  FlutterTts? _tts;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _tts = FlutterTts();
    
    // Configure TTS for child-friendly voice
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.45); // Slower for children
    await _tts!.setPitch(1.1); // Slightly higher pitch
    await _tts!.setVolume(1.0);
    
    // Use a friendly voice if available
    try {
      final voices = await _tts!.getVoices;
      if (voices != null && voices is List) {
        // Try to find a good voice for children
        for (final voice in voices) {
          if (voice is Map) {
            final name = voice['name']?.toString().toLowerCase() ?? '';
            if (name.contains('samantha') || name.contains('karen') || 
                name.contains('moira') || name.contains('alex')) {
              await _tts!.setVoice({'name': voice['name'], 'locale': voice['locale']});
              break;
            }
          }
        }
      }
    } catch (e) {
      // Use default voice
    }
    
    _isInitialized = true;
  }

  /// Speak a question prompt
  Future<void> speakQuestion(String prompt) async {
    await init();
    final text = "Find the word that rhymes with... $prompt!";
    await _tts?.speak(text);
  }

  /// Speak success message
  Future<void> speakSuccess() async {
    await init();
    final messages = [
      "Great job!",
      "You got it!",
      "Excellent!",
      "Well done!",
      "Perfect!",
    ];
    messages.shuffle();
    await _tts?.speak(messages.first);
  }

  /// Speak encouragement on wrong answer
  Future<void> speakEncouragement() async {
    await init();
    final messages = [
      "Try again!",
      "Almost there!",
      "Keep going!",
      "Nice try!",
    ];
    messages.shuffle();
    await _tts?.speak(messages.first);
  }

  /// Speak game complete message
  Future<void> speakComplete() async {
    await init();
    await _tts?.speak("Great job, Explorer! You finished the game!");
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    await _tts?.stop();
  }

  void dispose() {
    _tts?.stop();
    _tts = null;
    _isInitialized = false;
  }
}
