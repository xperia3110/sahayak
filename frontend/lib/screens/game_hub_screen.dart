import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'games/star_tracer_screen.dart';
// Import Echo Explorers & Monster Munch when created (using placeholders for now)

class GameHubScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final int childAge;

  const GameHubScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.childAge,
  });

  @override
  Widget build(BuildContext context) {
    // Child Mode Theme (Override parent theme locally or just use colorful widgets)
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Light Yellow/Warm background
      appBar: AppBar(
        title: Text("Hi, $childName! 👋", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Comic Sans MS')), // Use a playful font if available
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Let's Play & Learn!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildGameCard(
                    context,
                    title: "Star Tracer",
                    subtitle: "Trace the stars!",
                    disability: "Dysgraphia Screening",
                    color: Colors.purple.shade300,
                    icon: Icons.star,
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StarTracerScreen(
                          childId: int.tryParse(childId) ?? 0, 
                          childName: childName,
                        )),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildGameCard(
                    context,
                    title: "Echo Explorers",
                    subtitle: "Listen and find!",
                    disability: "Dyslexia Screening",
                    color: Colors.blue.shade300,
                    icon: Icons.hearing,
                    onTap: () {
                      _showComingSoon(context, "Echo Explorers");
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildGameCard(
                    context,
                    title: "Monster Munch",
                    subtitle: "Feed the hungry monsters!",
                    disability: "Dyscalculia Screening",
                    color: Colors.green.shade300,
                    icon: Icons.calculate,
                    onTap: () {
                       _showComingSoon(context, "Monster Munch");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String game) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$game is coming soon!")));
  }

  Widget _buildGameCard(BuildContext context, {required String title, required String subtitle, required String disability, required Color color, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)),
              ),
              child: Center(
                child: Icon(icon, size: 60, color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                       child: Text(
                        disability,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                     ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
