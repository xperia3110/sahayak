import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class MonsterAudioService {
  static final MonsterAudioService _instance = MonsterAudioService._internal();
  factory MonsterAudioService() => _instance;
  MonsterAudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _soundEnabled = false; 

  // Note: Audio files would need to be added to assets/audio/ folder
  // For now, sounds are disabled if files are missing to prevent errors
  
  Future<void> init() async {
    // Check if audio files exist, if not disable sound or handle gracefully
    try {
      // We assume assets are in assets/audio/
      // If we don't have them yet, this might fail or warn.
      // For now, let's try to set up.
      await _sfxPlayer.setSource(AssetSource('audio/correct.mp3'));
      _soundEnabled = true;
    } catch (e) {
      _soundEnabled = false;
      if (kDebugMode) {
        print('Audio files not found. Sound disabled. Add MP3 files to assets/audio/ to enable.');
      }
    }
  }

  Future<void> playEat() async {
    if (!_soundEnabled) return;
    await _playSound('audio/eat.mp3');
  }

  Future<void> playCorrect() async {
    if (!_soundEnabled) return;
    await _playSound('audio/correct.mp3');
  }

  Future<void> playWrong() async {
    if (!_soundEnabled) return;
    await _playSound('audio/wrong.mp3');
  }

  Future<void> playCelebrate() async {
    if (!_soundEnabled) return;
    await _playSound('audio/celebrate.mp3');
  }

  Future<void> playRoar() async {
    if (!_soundEnabled) return;
    await _playSound('audio/roar.mp3');
  }

  Future<void> _playSound(String assetPath) async {
    if (!_soundEnabled) return;
    
    try {
      if (kIsWeb) {
        await _sfxPlayer.play(AssetSource(assetPath));
      } else {
        // Create a new player for overlapping sounds
        final player = AudioPlayer();
        await player.play(AssetSource(assetPath));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound $assetPath: $e');
      }
    }
  }
}
