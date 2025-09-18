import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50], // same as login bg for consistency
      appBar: AppBar(
        title: const Text(
          "Sahayak",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👋 Welcome!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Choose what you want to do today:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Buttons or cards for navigation
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildHomeCard("📚 Learn", Colors.blue, () {
                    // TODO: Navigate to Learn Page
                  }),
                  _buildHomeCard("🎮 Play", Colors.green, () {
                    // TODO: Navigate to Play Page
                  }),
                  _buildHomeCard("🧠 Practice", Colors.orange, () {
                    // TODO: Navigate to Practice Page
                  }),
                  _buildHomeCard("📊 Progress", Colors.purple, () {
                    // TODO: Navigate to Progress Page
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color, // ✅ FIXED: removed [800]
            ),
          ),
        ),
      ),
    );
  }
}
