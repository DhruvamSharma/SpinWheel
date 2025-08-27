import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SpinWheel extends StatefulWidget {
  SpinWheel({super.key});
  final List<String> labels = [
    '₹100',
    '₹200',
    '₹300',
    '₹400',
    '₹500',
    '₹600',
    '₹700',
    '₹800',
  ];

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel> with TickerProviderStateMixin {

  late Ticker _ticker;
  late AnimationController _stopController;
  late Animation<double> _stopAnimation;

  double _currentAngle = 0;
  double _rotationSpeed = 0; // in radians/frame
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
    _stopController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _currentAngle += _rotationSpeed;
    });
  }

  void startSpinning() {
    if (_isSpinning) return;

    _rotationSpeed = 0.4; // Fast initial speed
    _isSpinning = true;
    _ticker.start();
  }

  void stopSpinning(int targetIndex) {
    if (!_isSpinning) return;
    _isSpinning = false;
    _ticker.stop();

    // Pick a segment
    final anglePerSegment = 2 * pi / widget.labels.length;
    final correction = (anglePerSegment / 2); // Right pointer = 0 radians
    final targetAngle = ((widget.labels.length + 1 - targetIndex) * anglePerSegment) - correction;

    const fullSpins = 4 * (2 * pi); // more spins to slow down nicely
    final finalAngle = fullSpins + targetAngle;

    _stopAnimation = Tween<double>(
      begin: 0,
      end: finalAngle,
    ).animate(CurvedAnimation(parent: _stopController, curve: Curves.easeOutCubic))
      ..addListener(() {
        setState(() {
          _currentAngle = _stopAnimation.value;
        });
      });

    _stopController.forward(from: 0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _currentAngle,
                  child: Builder(
                    builder: (context) {
                      const size = 300.0;
                      final segmentCount = widget.labels.length;
                      return SizedBox(
                        width: size,
                        height: size,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Paint the wheel
                            CustomPaint(
                              painter:
                                  SpinWheelPainter(labels: widget.labels),
                              size: const Size(size, size),
                            ),
                            // Overlay widgets
                            ...List.generate(segmentCount, (i) {
                              final sliceAngle = 2 * pi / segmentCount;
                              final centerAngle =
                                  i * sliceAngle + sliceAngle / 2;
                      
                              const radius = size / 3;
                              final dx = radius * cos(centerAngle);
                              final dy = radius * sin(centerAngle);
                      
                              return Transform.translate(
                                offset: Offset(dx, dy),
                                child: Transform.rotate(
                                  angle: centerAngle + pi / 2,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.card_giftcard,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      Text(
                                        '₹${(i + 1) * 100}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Pointer at 3 o'clock (right center)
                GestureDetector(
                  onTap: () {
                    if (_isSpinning) {
                      stopSpinning(1); // For demo, always stop at index 1
                    } else {
                      startSpinning();
                    }
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.arrow_right_alt,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: startSpinning,
                      child: const Text('Spin'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        stopSpinning(1);
                      },
                      child: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpinWheelPainter extends CustomPainter {
  const SpinWheelPainter({required this.labels});
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final segmentCount = labels.length;
    // find the center of the size
    final center = Offset(size.width / 2, size.height / 2);
    // find the radius as half the width
    final radius = size.width / 2;

    // how much a slice is in radians
    final sliceAngle = 2 * pi / segmentCount;

    // let's draw the segments
    // and then draw an arc from that angle to the next angle
    for (var i = 0; i < segmentCount; i++) {
      // for each segment, we need to calculate the start angle
      final startAngle = i * sliceAngle;

      // then we decide how we want to pain the slices
      final paint = Paint()
        ..color = i.isEven ? Colors.orangeAccent : Colors.deepOrange
        ..style = PaintingStyle.fill;

      // draw the segment (arc) on the canvas
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );
    }

    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
