import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pius_lab1/widgets/saw.dart';
import 'package:pius_lab1/widgets/woodBlock.dart';

class WoodCutter extends StatefulWidget {
  static const DELAY = 2000;

  final int xSize;
  final int ySize;
  final double blockLength;
  final bool isFrontLayer;

  bool shouldInitSaw = false;
  int sawX;
  int sawY;

  WoodCutter({Key key, this.xSize = 10, this.ySize = 10, this.blockLength = 42, this.isFrontLayer = true}) : super(key: key);

  initializeSaw(int x, int y) {
    shouldInitSaw = true;
    sawX = x;
    sawY = y;
  }

  @override
  WoodCutterState createState() {
    var state = WoodCutterState();

    if (shouldInitSaw) {
      shouldInitSaw = false;

      state.placeSawOnBuild(sawX, sawY);
    }

    return state;
  }
}

class WoodCutterState extends State<WoodCutter> with TickerProviderStateMixin {
  bool initSawOnBuild = false;
  bool isSawPlaced = false;
  int sawCoordX = 0;
  int sawCoordY = 0;
  double sawRealX = 0;
  double sawRealY = 0;

  AnimationController _sawXMoveAnimationController;
  Animation _sawXMoveAnimation;
  AnimationController _sawYMoveAnimationController;
  Animation _sawYMoveAnimation;
  int stepTimeMs = 1000;
  bool inputLocked = false;

  List<WoodBlock> woodBlocks = [];

  @override
  void initState() { 
    super.initState();

    for (int y = 0; y < widget.ySize; ++y) {
      for (int x = 0; x < widget.xSize; ++x) {
        GlobalKey<WoodBlockState> woodBlockStateKey = GlobalKey();
        woodBlocks.add(WoodBlock(woodBlockStateKey, x: x, y: y));
      } 
    }

    if (initSawOnBuild) {
      placeSaw(sawCoordX, sawCoordY);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.xSize * widget.blockLength,
      height: widget.ySize * widget.blockLength,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              overflow: Overflow.visible,
              children: [
                GridView.count(
                  crossAxisCount: widget.xSize,
                  children: woodBlocks
                ),
                if (isSawPlaced)
                  Positioned(
                    left: sawRealX,
                    top: sawRealY,
                    child: Saw(sawLength: widget.blockLength),
                  ),
              ],
            ),
          )
        ]
      ),
    );
  }

  clearBlocksBehind(int x, int y) async {
    var key = _findBlock(x, y).key as GlobalKey<WoodBlockState>;
    key.currentState.removeBlocksBehind();
  }

  addBlocksBehind(int x, int y) {
    var key = _findBlock(x, y).key as GlobalKey<WoodBlockState>;
    key.currentState.addBlocksBehind();
  }

  cutBlock(int x, int y) {
    _findBlock(x, y).isCutted = true;
  }

  restoreBlock(int x, int y) {
    _findBlock(x, y).isCutted = false;
  }

  placeSawOnBuild(int x, int y) {
    sawCoordX = x;
    sawCoordY = y;

    initSawOnBuild = true;
  }

  placeSaw(int x, int y) {
    isSawPlaced = true;

    sawCoordX = x;
    sawCoordY = y;

    var sawRealPos = _getSawRealPosition(sawCoordX, sawCoordY);
    sawRealX = sawRealPos[0];
    sawRealY = sawRealPos[1];
  }

  removeSaw() {
    isSawPlaced = false;
  }

  moveSawRelative(int dx, int dy, {bool withCut = true}) async {
    moveSaw(sawCoordX + dx, sawCoordY + dy, withCut: true);
  }

  moveSaw(int x, int y, {bool withCut = true}) {
    if (!inputLocked && isSawPlaced) {
      _moveSaw(x: x, y: y, withCut: withCut);
    }
  }

  _findBlock(int x, int y) {
    return woodBlocks
      .firstWhere((woodBlock) => woodBlock.x == x && woodBlock.y == y, orElse: () => null);
  }

  _moveSaw({int x, int y, bool withCut: true}) {
    inputLocked = true;

    var coords = _getSawRealPosition(x, y);
    double newRealX = coords[0];
    double newRealY = coords[1];

    _reinitXAxisAnimation(sawRealX, newRealX);
    _runAnimation(_sawXMoveAnimationController, _sawXMoveAnimation, withCut: withCut);

    _reinitYAxisAnimation(sawRealY, newRealY);
    _runAnimation(_sawYMoveAnimationController, _sawYMoveAnimation, withCut: withCut);
  }

  _reinitXAxisAnimation(double oldValue, double newValue) {
    _sawXMoveAnimationController?.stop();
    
    _sawXMoveAnimationController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: stepTimeMs
      ),
    );
    
    _sawXMoveAnimation = Tween<double>(
      begin: oldValue,
      end: newValue
    )
    .animate(_sawXMoveAnimationController);
  }

  _reinitYAxisAnimation(double oldValue, double newValue) {
    _sawYMoveAnimationController?.stop();
    
    _sawYMoveAnimationController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: stepTimeMs
      ),
    );

    _sawYMoveAnimation = Tween<double>(
      begin: oldValue,
      end: newValue
    )
    .animate(_sawYMoveAnimationController);
  }

  _runAnimation(AnimationController animationController, Animation animation, {bool withCut: true}) {
    animationController?.stop();

    animationController.addListener(() {
      setState(() {
        _saveSawPosition();
        if (withCut) {
          _cutWoodBlock();
        }
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        inputLocked = false;
      }
    });

    animationController.forward();
  }

  _saveSawPosition() {
    sawRealX = _sawXMoveAnimation?.value ?? sawRealX;
    sawRealY = _sawYMoveAnimation?.value ?? sawRealY;

    var sawCoords = _getSawCooords(sawRealX, sawRealY);
    sawCoordX = sawCoords[0];
    sawCoordY = sawCoords[1];
  }

  _cutWoodBlock() {
    GlobalKey<WoodBlockState> woodBlockStateKey = _findBlock(sawCoordX, sawCoordY)?.key;

    woodBlockStateKey?.currentState?.cut();
  }

  List<double> _getSawRealPosition(int coordX, int coordY) {
    double realX = coordX * widget.blockLength;
    double realY = coordY * widget.blockLength - widget.blockLength / 2;

    return [realX, realY];
  }

  List<int> _getSawCooords(double realX, double realY) {
    int coordX = (realX / widget.blockLength).round();
    int coordY = ((realY + widget.blockLength / 2) / widget.blockLength).round();

    return [coordX, coordY];
  }

  @override
  void dispose() {
    _sawXMoveAnimationController.dispose();

    super.dispose();
  }
}