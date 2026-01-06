import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ShootingStarWidget extends StatefulWidget {
  final Widget child;

  const ShootingStarWidget({super.key, required this.child});

  @override
  State<ShootingStarWidget> createState() => _ShootingStarWidgetState();
}

class _ShootingStarWidgetState extends State<ShootingStarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ShootingStar> _stars = [];
  final Random _rng = Random();
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() {
        setState(() {
          // Update stars
          _stars.removeWhere((star) => star.progress >= 1.0);
          for (var star in _stars) {
            star.progress += 0.01; // Speed control
          }
        });
      })
      ..repeat();

    // Spawn stars periodically (5-10 seconds as requested)
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    final delay = _rng.nextInt(5) + 5; // 5 to 9 seconds
    _spawnTimer = Timer(Duration(seconds: delay), () {
      if (mounted) {
        _spawnStar();
        _scheduleNextSpawn();
      }
    });
  }

  void _spawnStar() {
    setState(() {
      _stars.add(_ShootingStar(
        startX: _rng.nextDouble(),
        startY: _rng.nextDouble() * 0.5, // Top half mostly
        angle: _rng.nextDouble() * pi / 4 + pi / 8, // ~45 degrees
        length: 0.2 + _rng.nextDouble() * 0.1,
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child, // Background
        ..._stars.map((star) => CustomPaint(
          size: Size.infinite,
          painter: _ShootingStarPainter(star),
        )),
      ],
    );
  }
}

class _ShootingStar {
  double startX;
  double startY;
  double angle; // Radians
  double length; // Relative to screen width
  double progress = 0.0;

  _ShootingStar({required this.startX, required this.startY, required this.angle, required this.length});
}

class _ShootingStarPainter extends CustomPainter {
  final _ShootingStar star;

  _ShootingStarPainter(this.star);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, 100, 5)) // Placeholder bounds
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double x = star.startX * size.width + cos(star.angle) * size.width * star.progress;
    final double y = star.startY * size.height + sin(star.angle) * size.height * star.progress;

    final double tailX = x - cos(star.angle) * size.width * star.length * (1 - star.progress);
    final double tailY = y - sin(star.angle) * size.height * star.length * (1 - star.progress);

    // Simple glowing line
    paint.color = Colors.white.withOpacity(1.0 - star.progress);
    canvas.drawLine(Offset(tailX, tailY), Offset(x, y), paint);
    
    // Head glow
    canvas.drawCircle(Offset(x, y), 2, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
