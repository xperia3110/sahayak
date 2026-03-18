import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum MonsterState { idle, eat, happy, sad, celebrate }

class MonsterWidget extends StatefulWidget {
  final MonsterState state;

  const MonsterWidget({super.key, required this.state});

  @override
  State<MonsterWidget> createState() => _MonsterWidgetState();
}

class _MonsterWidgetState extends State<MonsterWidget> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _breathController;
  late ConfettiController _confettiController;
  Timer? _blinkTimer;
  bool _isBlinking = false;
  
  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);

    _breathController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000)
    )..repeat(reverse: true);

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _startBlinking();
  }

  void _startBlinking() {
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (math.Random().nextDouble() > 0.5) {
        setState(() => _isBlinking = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _isBlinking = false);
        });
      }
    });
  }

  @override
  void didUpdateWidget(MonsterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == MonsterState.celebrate && oldWidget.state != MonsterState.celebrate) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _breathController.dispose();
    _confettiController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bodyColor;
    Color bellyColor;
    double mouthOpenness = 0.0;
    bool isSad = false;
    double bounceHeight = 15.0;
    bool showTeeth = false;
    
    switch (widget.state) {
      case MonsterState.idle:
        bodyColor = const Color(0xFFFF9800); // Orange
        bellyColor = const Color(0xFFFFB74D);
        mouthOpenness = 0.3;
        showTeeth = true;
        break;
      case MonsterState.eat:
        bodyColor = const Color(0xFFFF9800);
        bellyColor = const Color(0xFFFFB74D);
        mouthOpenness = 1.0; 
        bounceHeight = 8.0;
        showTeeth = true;
        break;
      case MonsterState.happy:
        bodyColor = const Color(0xFF4CAF50); // Green
        bellyColor = const Color(0xFF81C784);
        mouthOpenness = 0.7; 
        bounceHeight = 25.0;
        showTeeth = true;
        break;
      case MonsterState.sad:
        bodyColor = const Color(0xFF607D8B); // Blue-grey
        bellyColor = const Color(0xFF90A4AE);
        mouthOpenness = 0.2;
        isSad = true;
        bounceHeight = 3.0;
        break;
      case MonsterState.celebrate:
        bodyColor = const Color(0xFF9C27B0); // Purple
        bellyColor = const Color(0xFFBA68C8);
        mouthOpenness = 0.8;
        bounceHeight = 35.0;
        showTeeth = true;
        break;
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -math.pi / 2,
            emissionFrequency: 0.03,
            numberOfParticles: 25,
            maxBlastForce: 100,
            minBlastForce: 80,
            gravity: 0.15,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow], 
          ),
        ),

        // Monster Animation
        AnimatedBuilder(
          animation: Listenable.merge([_bounceController, _breathController]),
          builder: (context, child) {
            double bounce = math.sin(_bounceController.value * math.pi) * bounceHeight;
            double breath = _breathController.value * 0.08 + 0.96;

            Widget body = Transform.scale(
              scale: breath,
              child: Transform.translate(
                offset: Offset(0, -bounce),
                child: _buildMonsterBody(bodyColor, bellyColor, mouthOpenness, isSad, showTeeth),
              ),
            );

            if (widget.state == MonsterState.celebrate) {
               return Transform.rotate(
                 angle: math.sin(_bounceController.value * 2 * math.pi) * 0.2,
                 child: body,
               );
            }
            return body;
          },
        ),
      ],
    );
  }

  Widget _buildMonsterBody(Color color, Color bellyColor, double mouthFactor, bool isSad, bool showTeeth) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main Body
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
          ),
          
          // Belly
          Positioned(
            bottom: 30,
            child: Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: bellyColor,
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),

          // Horns
          Positioned(
            top: 10,
            left: 30,
            child: _buildHorn(color),
          ),
          Positioned(
            top: 10,
            right: 30,
            child: _buildHorn(color),
          ),

          // Eyes
          Positioned(
            top: 60,
            left: 55,
            child: _buildEye(isSad),
          ),
          Positioned(
            top: 60,
            right: 55,
            child: _buildEye(isSad),
          ),

          // Mouth
          Positioned(
            bottom: 50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 25 + (70 * mouthFactor),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(isSad ? 0 : 60),
                  bottomRight: Radius.circular(isSad ? 0 : 60),
                  topLeft: Radius.circular(isSad ? 60 : 15),
                  topRight: Radius.circular(isSad ? 60 : 15),
                ),
              ),
            ),
          ),
          
          // Teeth
          if (showTeeth && mouthFactor > 0.4)
            Positioned(
              bottom: 50 + (15 + (35 * mouthFactor)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTooth(),
                  const SizedBox(width: 8),
                  _buildTooth(),
                  const SizedBox(width: 8),
                  _buildTooth(),
                ],
              ),
            ),

          // Tongue (when eating)
          if (mouthFactor > 0.7)
            Positioned(
              bottom: 55,
              child: Container(
                width: 40,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.pink.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorn(Color color) {
    return Container(
      width: 20,
      height: 35,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
    );
  }

  Widget _buildEye(bool isSad) {
    if (_isBlinking) {
       return Container(
         width: 45,
         height: 6,
         decoration: BoxDecoration(
           color: Colors.black.withOpacity(0.6),
           borderRadius: BorderRadius.circular(5),
         ),
       );
    }
    
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      alignment: isSad ? Alignment.bottomCenter : Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildTooth() {
    return Container(
      width: 18,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
    );
  }
}
