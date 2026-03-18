import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../screens/games/monster_munch/services/monster_audio_service.dart';
import '../../../../screens/games/monster_munch/widgets/animated_background.dart';
import 'subitizing_screen.dart';
import 'comparison_screen.dart';

class MonsterMenuScreen extends StatelessWidget {
  final int childId;

  const MonsterMenuScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    // Initialize audio service when menu opens
    MonsterAudioService().init();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🦖 Monster Munch!',
                      style: GoogleFonts.comicNeue(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          const Shadow(blurRadius: 10, color: Colors.black26, offset: Offset(2, 2))
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Feed the hungry monster!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 50),
                    _GameModeButton(
                      title: 'Feed the Monster',
                      subtitle: 'Count & Remember',
                      color: Colors.orange.shade600,
                      icon: Icons.cookie,
                      onTap: () {
                        MonsterAudioService().playCorrect();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SubitizingScreen(childId: childId)),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _GameModeButton(
                      title: 'Snack Battle',
                      subtitle: 'Which has more?',
                      color: Colors.green.shade600,
                      icon: Icons.restaurant,
                      onTap: () {
                         MonsterAudioService().playCorrect();
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ComparisonScreen(childId: childId)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GameModeButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 6),
              blurRadius: 12,
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 45, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
