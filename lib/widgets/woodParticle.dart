import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_animations/simple_animations.dart';

class WoodParticle {
  Animatable tween;
  AnimationProgress progress;
  final Duration duration = Duration(milliseconds: 2000);

  Color color;
  double width;
  double height;
  final Random random = Random();

  // Generates random visual particle parameters
  WoodParticle(Duration time, double blockLength) {
    int redColorPart = (180 * (1 + 0.2 * random.nextDouble())).toInt();
    int greenColorPart = (145 * (1 + 0.2 * random.nextDouble())).toInt();
    int blueColorPart = (90 * (1 + 0.2 * random.nextDouble())).toInt();
    color = Color.fromRGBO(redColorPart, greenColorPart, blueColorPart, 1);
    
    bool rotated = random.nextBool();
    width =  rotated ? 0.3 * blockLength : blockLength;
    height = rotated ? blockLength : 0.3 * blockLength;

    final x = 4 * blockLength * random.nextDouble() * (random.nextBool() ? 1 : -1);
    final y = 4 * blockLength * random.nextDouble() * (random.nextBool() ? 1 : -1);

    tween = MultiTrackTween([
      Track("x").add(Duration(seconds: 1), Tween(begin: 0.0, end: x)),
      Track("y").add(Duration(seconds: 1), Tween(begin: 0.0, end: y)),
      Track("scale").add(Duration(seconds: 1), Tween(begin: 0.2, end: 0.0))
    ]);

    progress = AnimationProgress(
        startTime: time, 
        duration: duration
    );
  }

  // Returns widget based on particle visual parameters 
  buildWidget(Duration time) {
    final animation = tween.transform(progress.progress(time));

    return Positioned(
      left: animation["x"],
      top: animation["y"],
      child: Transform.scale(
        scale: animation["scale"],
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: color, 
              borderRadius: BorderRadius.circular(5)
          ),
        ),
      ),
    );
  }
}