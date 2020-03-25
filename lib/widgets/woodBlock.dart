import 'package:flutter/widgets.dart';
import 'package:pius_lab1/widgets/woodParticle.dart';
import 'package:simple_animations/simple_animations/rendering.dart';

class WoodBlock extends StatefulWidget {
  final Key key;
  final int x;
  final int y;
  final double blockLength;
  bool isCutted = false;

  WoodBlock(this.key, {this.x = 0, this.y = 0, this.blockLength = 40}) : super(key: key);

  @override
  State<StatefulWidget> createState() => WoodBlockState();
}

class WoodBlockState extends State<WoodBlock> {
  static const WOOD_PARTICLE_COUNT = 30;

  static final Image SHADOW_WOOD_IMAGE = Image.asset("assets/img/shadow-wood.png");
  static final Image WOOD_IMAGE = Image.asset("assets/img/wood.png");
  static final Widget EMPTY_BLOCK = SizedBox();

  Duration currentTime = Duration.zero;
  bool hasBlockBehind = true;

  final List<WoodParticle> particles = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Rendering(
        onTick: (time) => _manageParticleLifecycle(time),
        builder: (context, time) { 
            return Stack(
              overflow: Overflow.clip,
              children: [
                _getImage(),
                ...particles.map((particle) => particle.buildWidget(time)),
                Text("${widget.x} ${widget.y}", style: TextStyle(fontSize: 10.0))
              ],
            );
        }
      )
    );
  }

  _getImage() => !widget.isCutted
    ? WOOD_IMAGE
    : hasBlockBehind
      ? SHADOW_WOOD_IMAGE
      : EMPTY_BLOCK;

  _manageParticleLifecycle(Duration time) {
    currentTime = time;

    particles.removeWhere((particle) {
      return particle.progress.progress(time) == 1;
    });
  }

  cut({Duration time}) => setState(() {
    if (!widget.isCutted) {
      Iterable.generate(WOOD_PARTICLE_COUNT)
        .forEach((i) => particles.add(WoodParticle(time ?? currentTime, widget.blockLength)));
      widget.isCutted = true;
    }
  });

  removeBlocksBehind() => setState(() => hasBlockBehind = false);
  
  addBlocksBehind() => setState(() => hasBlockBehind = true);
}