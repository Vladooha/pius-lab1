import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class Saw extends StatefulWidget {
  int initialX;
  int initialY;
  final double sawLength;
  final bool isFrontView;

  Saw({this.initialX, this.initialY, this.sawLength = 40, this.isFrontView = true});

  @override
  State<StatefulWidget> createState() => SawState();
}

class SawState extends State<Saw> with SingleTickerProviderStateMixin {
  static const ANIMATION_TIME_MS = 800;
  static const MIN_ANGLE = 0.0;
  static const MAX_ANGLE = 2 * math.pi;

  int x;
  int y;

  AnimationController _animationController;
  Animation _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _prepareAnimation();
  }

  SawState({this.x = 0, this.y = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.sawLength,
      height: widget.sawLength,
      child: Transform.rotate(
        angle: _getAngle(), 
        child: Image.asset("assets/img/circular-saw.png")
      )
    );
  }
  
  _prepareAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: ANIMATION_TIME_MS
      ),
    );

    _rotateAnimation = Tween<double>(
        begin: MAX_ANGLE,
        end: MIN_ANGLE
    )
    .animate(_animationController)
    ..addStatusListener((status) {
       if (status == AnimationStatus.completed) {
         _animationController.repeat();
       } else if (status == AnimationStatus.dismissed) {
         _animationController.forward();
       }
     });

    _animationController.addListener(() {
      setState(() {});
    });

    _animationController.forward();
  }

  double _getAngle() => widget.isFrontView
    ? _rotateAnimation.value
    : MIN_ANGLE;

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }
}