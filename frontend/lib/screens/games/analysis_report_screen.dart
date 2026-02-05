import 'package:flutter/material.dart';

class AnalysisReportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  
  const AnalysisReportScreen({super.key, required this.results});

  double get averageScore {
    if (results.isEmpty) return 0;
    final total = results.fold<double>(0, (sum, r) => sum + (r['score'] ?? 0));
    return total / results.length;
  }

  String _getPerformanceLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Needs Practice';
    return 'Keep Trying';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final avg = averageScore;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Analysis Report', style: TextStyle(color: Colors.white)),
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
              // Overall Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor(avg).withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getScoreColor(avg), width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Overall Score',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                        color: _getScoreColor(avg),
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getPerformanceLevel(avg),
                      style: TextStyle(
                        color: _getScoreColor(avg),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Per-Letter Breakdown
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Letter Breakdown',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              
              ...results.map((result) => _buildLetterCard(result)),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.replay, color: Colors.black),
                      label: const Text('Play Again', style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text('Home', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildLetterCard(Map<String, dynamic> result) {
    final letter = result['letter'] ?? '?';
    final score = (result['score'] ?? 0).toDouble();
    final jitter = (result['jitter'] ?? 0).toDouble();
    final velocity = (result['velocity_consistency'] ?? 0).toDouble();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Letter
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getScoreColor(score).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _getScoreColor(score)),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: _getScoreColor(score),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Metrics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(color: _getScoreColor(score), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Steadiness', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      jitter < 100 ? 'Good' : jitter < 300 ? 'Fair' : 'Shaky',
                      style: TextStyle(
                        color: jitter < 100 ? Colors.green : jitter < 300 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Flow', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      velocity < 0.5 ? 'Smooth' : velocity < 1.0 ? 'Variable' : 'Choppy',
                      style: TextStyle(
                        color: velocity < 0.5 ? Colors.green : velocity < 1.0 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
