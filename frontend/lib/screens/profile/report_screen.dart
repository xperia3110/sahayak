import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ReportScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await ApiService.getChildReport(widget.childId, auth.user!.token!);
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getRiskColor(double risk) {
    if (risk >= 0.6) return Colors.red;
    if (risk >= 0.4) return Colors.orange;
    return Colors.green;
  }

  String _getRiskLabel(double risk) {
    if (risk >= 0.6) return "High Risk";
    if (risk >= 0.4) return "Moderate Risk";
    return "Low Risk";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.childName}\'s Report'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildReportContent(),
    );
  }

  Widget _buildReportContent() {
    if (_reportData == null) return const Center(child: Text("No data available"));
    
    // Check if it's the "No games played" message
    if (_reportData!.containsKey('message')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              _reportData!['message'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_reportData!['summary'] ?? ''),
          ],
        ),
      );
    }

    final readRisk = _reportData!['dyslexia_risk'] ?? 0.0;
    final writeRisk = _reportData!['dysgraphia_risk'] ?? 0.0;
    final mathRisk = _reportData!['dyscalculia_risk'] ?? 0.0;
    final summary = _reportData!['summary'] ?? "Ready.";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Overall Assessment",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(summary),
          const SizedBox(height: 24),
          const Text(
            "Detailed Analysis",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildRiskCard("Dyslexia (Reading)", readRisk, Icons.menu_book),
          const SizedBox(height: 12),
          _buildRiskCard("Dysgraphia (Writing)", writeRisk, Icons.edit),
          const SizedBox(height: 12),
          _buildRiskCard("Dyscalculia (Math)", mathRisk, Icons.calculate),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics, size: 40, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(String title, double riskValue, IconData icon) {
    final color = _getRiskColor(riskValue);
    final label = _getRiskLabel(riskValue);
    final percent = (riskValue * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 24,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: riskValue,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  strokeWidth: 6,
                ),
              ),
              Text("$percent%", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
