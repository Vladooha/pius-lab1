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

  // Places saw on current coordinates
  // `x` - saw x coordinate
  // `y` - saw x coordinate
  initializeSaw(int x, int y) {
    shouldInitSaw = true;
    sawX = x;
    sawY = y;
  }

  // Initializing widget state
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

  // Initializing state variables
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

  // Draws wood cutter surface on screen
  // `context` - context of visual widget tree
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

  // Removes all blocks behind current
  // `x` - x coordintae of block
  // `y` - y coordintae of block
  clearBlocksBehind(int x, int y) async {
    var key = _findBlock(x, y).key as GlobalKey<WoodBlockState>;
    key.currentState.removeBlocksBehind();
  }

  // Adds blocks behind current
  // `x` - x coordintae of block
  // `y` - y coordintae of block
  addBlocksBehind(int x, int y) {
    var key = _findBlock(x, y).key as GlobalKey<WoodBlockState>;
    key.currentState.addBlocksBehind();
  }

  // Cuts current block
  // `x` - x coordintae of block
  // `y` - y coordintae of block
  cutBlock(int x, int y) {
    _findBlock(x, y).isCutted = true;
  }

  // Recreates blocks
  // `x` - x coordintae of block
  // `y` - y coordintae of block
  restoreBlock(int x, int y) {
    _findBlock(x, y).isCutted = false;
  }

  // Recreates blocks
  // `x` - x coordintae of block
  // `y` - y coordintae of block
  placeSawOnBuild(int x, int y) {
    sawCoordX = x;
    sawCoordY = y;

    initSawOnBuild = true;
  }

  // Replacing saw by current coordinates
  // `x` - new x coordinate of saw
  // `y` - new y coordintae of block
  placeSaw(int x, int y) {
    isSawPlaced = true;

    sawCoordX = x;
    sawCoordY = y;

    var sawRealPos = _getSawRealPosition(sawCoordX, sawCoordY);
    sawRealX = sawRealPos[0];
    sawRealY = sawRealPos[1];
  }

  // Removing saw from field
  removeSaw() {
    isSawPlaced = false;
  }

  // Move saw by x and y offset
  // `dx` - x offset
  // `dy` - y offset
  // `withCut` - should block be cutted
  moveSawRelative(int dx, int dy, {bool withCut = true}) async {
    moveSaw(sawCoordX + dx, sawCoordY + dy, withCut: true);
  }

  // Move saw by coordinates
  // `x` - new x coordinate
  // `y` - new y coordinate
  // `withCut` - should block be cutted
  moveSaw(int x, int y, {bool withCut = true}) {
    if (!inputLocked && isSawPlaced) {
      _moveSaw(x: x, y: y, withCut: withCut);
    }
  }

  // Returns block on current coordinates
  // `x` - block x coordinate
  // `y` - block y coordinate
  WoodBlock _findBlock(int x, int y) {
    return woodBlocks
      .firstWhere((woodBlock) => woodBlock.x == x && woodBlock.y == y, orElse: () => null);
  }

  // Replacing saw on current coordinates
  // `x` - new saw x coordinate
  // `y` - new saw y coordinate
  // `withCut` - should wood block on (`x`, `y`) coordinates be cutted
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

  // Creates saw animation on X axis
  // `oldValue` - old left-top pixel on screen
  // `oldValue` - new left-top pixel on screen
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

  // Creates saw animation on Y axis
  // `oldValue` - old left-top pixel on screen
  // `oldValue` - new left-top pixel on screen
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

  // Starts saw animation
  // `animationController` - animation variables holder
  // `animation` - animation event listener
  // `withCut` - should catched blocks be cutted
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

  // Saves new saw real and coordinates positions
  _saveSawPosition() {
    sawRealX = _sawXMoveAnimation?.value ?? sawRealX;
    sawRealY = _sawYMoveAnimation?.value ?? sawRealY;

    var sawCoords = _getSawCooords(sawRealX, sawRealY);
    sawCoordX = sawCoords[0];
    sawCoordY = sawCoords[1];
  }

  // Cutting block on position where saw placed
  _cutWoodBlock() {
    GlobalKey<WoodBlockState> woodBlockStateKey = _findBlock(sawCoordX, sawCoordY)?.key;

    woodBlockStateKey?.currentState?.cut();
  }

  // Converts coordinates to real position
  // `coordX` - saw x coordinate
  // `coordY` - saw y coordinate
  List<double> _getSawRealPosition(int coordX, int coordY) {
    double realX = coordX * widget.blockLength;
    double realY = coordY * widget.blockLength - widget.blockLength / 2;

    return [realX, realY];
  }

  // Converts real positions to coordinates
  // `realX` - saw x real position
  // `realY` - saw y real position
  List<int> _getSawCooords(double realX, double realY) {
    int coordX = (realX / widget.blockLength).round();
    int coordY = ((realY + widget.blockLength / 2) / widget.blockLength).round();

    return [coordX, coordY];
  }

  // Widget destructor
  @override
  void dispose() {
    _sawXMoveAnimationController.dispose();

    super.dispose();
  }
}