import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert'; // For analyze response parsing if needed in logic, but it's in service.
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/child.dart';
import '../../widgets/shooting_star_bg.dart';
import '../../painters/neon_path_painter.dart';
import '../../widgets/stardust_path_animator.dart';

class StarTracerScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const StarTracerScreen({super.key, required this.childId, required this.childName});

  @override
  State<StarTracerScreen> createState() => _StarTracerScreenState();
}

class _StarTracerScreenState extends State<StarTracerScreen> {
  // List<Child> _children = []; // Removed
  // Child? _selectedChild; // Removed
  bool _isLoading = true; // Still use for session creation
  int? _sessionId;
  
  // Drawing state
  List<Offset?> _points = [];
  final List<Map<String, dynamic>> _recordedPoints = []; // For backend: {x, y, t}
  Map<String, dynamic>? _debugMetrics; // For Debug Panel
  
  // Game Logic
  Path? _targetPath;
  bool _showGuide = true; // Show guide first

  @override
  void initState() {
    super.initState();
    // Start session immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  // Calculate path based on screen size
  Path _createStarPath(Size size) {
    Path path = Path();
    double cx = size.width / 2;
    double cy = size.height / 2;
    double r = size.width * 0.4; // Responsive radius
    double rInner = r * 0.4; // Inner radius for star

    double angle = -pi / 2; // Start at top
    double step = pi / 5; // 36 degrees (10 steps for 5 points)

    path.moveTo(cx + r * cos(angle), cy + r * sin(angle));
    for (int i = 0; i < 5; i++) {
      angle += step;
      path.lineTo(cx + rInner * cos(angle), cy + rInner * sin(angle));
      angle += step;
      path.lineTo(cx + r * cos(angle), cy + r * sin(angle));
    }
    path.close();
    return path;
  }

  // Removed _fetchChildren and _showChildSelectionDialog

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
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start session: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _submitDrawing() async {
    if (_sessionId == null || _recordedPoints.isEmpty) return;

    try {
      final authProvider = context.read<AuthProvider>();
      
      // 1. Submit Data for Storage (Optional/Parallel)
      // await ApiService.submitDrawingData(...) 

      // 2. Analyze for Immediate Feedback (Debug Panel)
      final results = await ApiService.analyzeStroke(
        authProvider.user!.token!,
        _recordedPoints,
      );
      
      if (!mounted) return;

      setState(() {
        _debugMetrics = results;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis Complete! Check Debug Panel.')),
      );
      // Do not pop context, so they can see the debug panel
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to analyze: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Star Tracer', style: TextStyle(color: Colors.white70)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          if (_sessionId != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submitDrawing,
            )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF2E003E), // Deep Violet
                  Colors.black,
                ],
              ),
            ),
            child: ShootingStarWidget(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                  : _sessionId == null
                      ? const Center(child: Text('Initializing game...', style: TextStyle(color: Colors.white54)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Generate path if not ready
                            if (_targetPath == null) {
                              _targetPath = _createStarPath(constraints.biggest);
                            }
                            
                            return Stack(
                              children: [
                                // Layer 1: Stardust Guide Animation
                                if (_showGuide)
                                  StardustPathAnimator(
                                    path: _targetPath!,
                                    duration: const Duration(seconds: 3),
                                    onAnimationComplete: () {
                                      setState(() {
                                        _showGuide = false; // Allow drawing
                                      });
                                    },
                                  ),
                                
                                // Layer 2: Static Guide (Faint Background) - Visible during drawing
                                if (!_showGuide)
                                  CustomPaint(
                                    painter: _StaticGuidePainter(_targetPath!),
                                    size: Size.infinite,
                                  ),

                                // Layer 3: User Interaction
                                GestureDetector(
                                  onPanUpdate: (details) {
                                    if (_showGuide) return; // Block input during animation
                                    setState(() {
                                      RenderBox renderBox = context.findRenderObject() as RenderBox;
                                      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                                      _points.add(localPosition);
                                      
                                      _recordedPoints.add({
                                        'x': localPosition.dx,
                                        'y': localPosition.dy,
                                        't': DateTime.now().millisecondsSinceEpoch,
                                      });
                                    });
                                  },
                                  onPanEnd: (details) {
                                      if (_showGuide) return;
                                      _points.add(null);
                                  },
                                  child: CustomPaint(
                                    painter: NeonPathPainter(points: _points),
                                    size: Size.infinite,
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
            ),
          ),
          
          // Developer Debug Panel Overlay
          if (_debugMetrics != null)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("DEBUG: Kinematics", style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.cyan),
                    Text("Score: ${_debugMetrics!['score'].toStringAsFixed(1)}", style: const TextStyle(color: Colors.white)),
                    Text("RMSE: ${_debugMetrics!['rmse'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("Jitter: ${_debugMetrics!['jitter'].toStringAsFixed(2)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                         setState(() {
                           _debugMetrics = null;
                           _points.clear();
                           _recordedPoints.clear();
                           // We can reset guide here if we want replay
                           // _showGuide = true; 
                         });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.withOpacity(0.3)),
                      child: const Text("Reset", style: TextStyle(color: Colors.cyan)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// DrawingPainter class removed - using NeonPathPainter

class _StaticGuidePainter extends CustomPainter {
  final Path path;
  _StaticGuidePainter(this.path);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      // Use simple DashPathEffect if needed, or manually draw points? 
      // Manual approach is safer if PathDashPathEffect is troublesome.
      // But PathDashPathEffect is standard. Let's try fixing the namespace.
      // Maybe the error is misleading and it's simply a missing import or alias mismatch.
      // I'll assume alias 'ui' is correct but maybe 'PathDashPathEffectStyle' needs specific handling?
      // No, it's an enum. ui.PathDashPathEffectStyle.rotate
    );
    
    // Manual dash effect fallback if the fancy one fails
    // Actually, let's just make it a detailed Solid line for now to fix the build 
    // and see if that resolves the error. A solid guide is acceptable MVP.
    // Or I can use a simpler dash pattern if I had a helper, but I don't.
    // I will comment out the pathEffect for now to get it building, 
    // unless I'm sure about the syntax.
    // Wait, I can try to use just `ui.PathDashPathEffect` again but careful.
    // I'll just remove pathEffect to unblock the build. Minimal aesthetic loss.
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
