import 'package:flutter/material.dart';

class EchoReportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const EchoReportScreen({super.key, required this.results});

  int get correctCount => results.where((r) => r['is_correct'] == true).length;
  int get totalCount => results.length;
  double get accuracy => totalCount > 0 ? (correctCount / totalCount) * 100 : 0;
  
  double get averageReactionTime {
    if (results.isEmpty) return 0;
    final total = results.fold<int>(0, (sum, r) => sum + (r['reaction_time_ms'] as int));
    return total / results.length;
  }

  String _getPerformanceLevel() {
    if (accuracy >= 80) return 'Excellent';
    if (accuracy >= 60) return 'Good';
    if (accuracy >= 40) return 'Needs Practice';
    return 'Keep Trying';
  }

  Color _getAccuracyColor() {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.lightGreen;
    if (accuracy >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getReactionTimeAssessment() {
    if (averageReactionTime < 2000) return 'Quick responses';
    if (averageReactionTime < 4000) return 'Normal processing';
    return 'Delayed processing';
  }

  Color _getReactionTimeColor() {
    if (averageReactionTime < 2000) return Colors.green;
    if (averageReactionTime < 4000) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Echo Explorers Report',
          style: TextStyle(color: Colors.lightGreen),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Accuracy Card
              _buildMetricCard(
                title: 'Phonological Accuracy',
                value: '${accuracy.toStringAsFixed(0)}%',
                subtitle: '$correctCount / $totalCount correct',
                level: _getPerformanceLevel(),
                color: _getAccuracyColor(),
                icon: Icons.check_circle,
              ),

              const SizedBox(height: 16),

              // Reaction Time Card
              _buildMetricCard(
                title: 'Average Response Time',
                value: '${(averageReactionTime / 1000).toStringAsFixed(1)}s',
                subtitle: _getReactionTimeAssessment(),
                level: averageReactionTime < 3000 ? 'Good' : 'Needs Attention',
                color: _getReactionTimeColor(),
                icon: Icons.timer,
              ),

              const SizedBox(height: 24),

              // Per-Question Breakdown
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Question Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ...results.asMap().entries.map((entry) => 
                _buildQuestionCard(entry.key + 1, entry.value)
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.replay, color: Colors.black),
                      label: const Text(
                        'Play Again',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        'Home',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String level,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), Colors.black.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int number, Map<String, dynamic> result) {
    final isCorrect = result['is_correct'] as bool;
    final reactionTime = result['reaction_time_ms'] as int;
    final prompt = result['prompt'] as String;
    final userAnswer = result['user_answer'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              color: isCorrect ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Question Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rhyme for: $prompt',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Answer: $userAnswer',
                  style: TextStyle(
                    color: isCorrect ? Colors.green[300] : Colors.red[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Reaction Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(reactionTime / 1000).toStringAsFixed(1)}s',
                style: TextStyle(
                  color: reactionTime < 3000 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'response',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
