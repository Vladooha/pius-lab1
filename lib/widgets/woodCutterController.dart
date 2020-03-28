import 'package:flutter/material.dart';
import 'package:pius_lab1/widgets/woodCutter.dart';

enum Axis {
  X, Y, Z
}

class Surface {
  static const Surface XY = Surface._(Axis.Z);
  static const Surface XZ = Surface._(Axis.Y);
  static const Surface YZ = Surface._(Axis.X);
  
  final Axis invisibleAxis;

  const Surface._(this.invisibleAxis);
}

class RelativeCoordinate {
  int _x;
  int _y;
  int _z;

  // Creates coordinate on current coordinates relative to chosen surface
  // `x` - x coordinate
  // `y` - y coordinate
  // `z` - z coordinate
  // `surf` - chosen surface
  RelativeCoordinate({int x = 0, int y = 0, int z = 0, Surface surf = Surface.XY}) {
    setByAxis(imgX: x, imgY: y, imgZ: z, surf: surf);
  }

  // Creates coordinate by offset relative to chosen surface
  // `x` - x coordinate
  // `y` - y coordinate
  // `z` - z coordinate
  // `surf` - chosen surface
  RelativeCoordinate.from(RelativeCoordinate coordinate, {int dx = 0, int dy = 0, int dz = 0, Surface surf = Surface.XY}) {
    setByCoordinate(coordinate, dx: dx, dy: dy, dz: dz, surf: surf);
  }

  // Sets coordinate on current coordinates relative to chosen surface
  // `x` - x coordinate
  // `y` - y coordinate
  // `z` - z coordinate
  // `surf` - chosen surface
  setByAxis({int imgX, int imgY, int imgZ, Surface surf = Surface.XY}) {
    if (surf == Surface.XY) {
      _x = imgX ?? _x;
      _y = imgY ?? _y;
      _z = imgZ ?? _z;
    } else if (surf == Surface.XZ) {
      _x = imgX ?? _x;
      _y = imgZ ?? _y;
      _z = imgY ?? _z;
    } else if (surf == Surface.YZ) {
      _x = imgY ?? _x;
      _y = imgZ ?? _y;
      _z = imgX ?? _z;
    }
  }

  // Sets coordinate by offset relative to chosen surface
  // `x` - x coordinate
  // `y` - y coordinate
  // `z` - z coordinate
  // `surf` - chosen surface
  setByCoordinate(RelativeCoordinate coordinate, {int dx = 0, int dy = 0, int dz = 0, Surface surf = Surface.XY}) {
    Map coords = coordinate.getAxes();
    setByAxis(imgX: coords[Axis.X] + dx, imgY: coords[Axis.Y] + dy, imgZ: coords[Axis.Z] + dz, surf: surf);
  }

  // Returns coordinate relative to chosen surface
  // `surf` - chosen surface
  Map<Axis, int> getAxes({Surface surf = Surface.XY}) {
    if (surf == Surface.XY) {
      return {Axis.X: _x, Axis.Y: _y, Axis.Z: _z};
    } else if (surf == Surface.XZ) {
      return {Axis.X: _x, Axis.Y: _z, Axis.Z: _y};
    } else if (surf == Surface.YZ) {
     return {Axis.X: _y, Axis.Y: _z, Axis.Z: _x};
    }

    return null;
  }

  // Returns x coordinate relative to chosen surface
  // `surf` - chosen surface
  int getX({Surface surf: Surface.XY}) => getAxes(surf: surf)[Axis.X];

  // Returns y coordinate relative to chosen surface
  // `surf` - chosen surface
  int getY({Surface surf: Surface.XY}) => getAxes(surf: surf)[Axis.Y];
  
  // Returns z coordinate relative to chosen surface
  // `surf` - chosen surface
  int getZ({Surface surf: Surface.XY}) => getAxes(surf: surf)[Axis.Z]; 

  // Creates array of coordinate offsets from zero to `diff`
  // `diff` - array size
  List<int> _createAxisOffsets(int diff) => Iterable.generate(diff.abs() + 1, (offset) => diff > 0 ? offset++ : offset--).toList();

  // Equality operator override
  @override
  bool operator ==(o) => o is RelativeCoordinate && _x == o.getX() && _y == o.getY() && _z == o.getZ();

  // Hashcode generator
  @override
  int get hashCode => _x*_x*_x + _y*_y + _z;
}

class WoodCutterController extends StatelessWidget {
  bool inputLocked = false;
  
  final Map<Axis, int> axisLimits = {};
  final double blockLength = 42.0;

  RelativeCoordinate sawCoordinate;
  Map<Surface, WoodCutter> woodCutterMap = {};
  Set<RelativeCoordinate> cuttedBlocks = {};

  // Initializing wood cutter surfaces
  WoodCutterController({int xLimit = 5, int yLimit = 5, int zLimit = 5, int sawX = 0, int sawY = 0}) {
    axisLimits[Axis.X] = xLimit;
    axisLimits[Axis.Y] = yLimit;
    axisLimits[Axis.Z] = zLimit;

    woodCutterMap[Surface.XY] = WoodCutter(
      key: GlobalKey<WoodCutterState>(), 
      blockLength: blockLength, 
      xSize: axisLimits[Axis.X], 
      ySize: axisLimits[Axis.Y]
    );
    woodCutterMap[Surface.XZ] = WoodCutter(
      key: GlobalKey<WoodCutterState>(), 
      blockLength: blockLength, 
      xSize: axisLimits[Axis.X], 
      ySize: axisLimits[Axis.Z]
    );
    woodCutterMap[Surface.YZ] = WoodCutter(
      key: GlobalKey<WoodCutterState>(), 
      blockLength: blockLength, 
      xSize: axisLimits[Axis.Y], 
      ySize: axisLimits[Axis.Z]
    );

    sawCoordinate = RelativeCoordinate(x: sawX, y: sawY, z: -1);
    woodCutterMap[Surface.XY].initializeSaw(sawX, sawY);
    woodCutterMap[Surface.XZ].initializeSaw(sawX, -1);
    woodCutterMap[Surface.YZ].initializeSaw(sawY, -1);
  }

  // Draws wood cutter surfaces on screen
  // `context` - context of visual widget tree
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(padding: EdgeInsets.all(5.0), child: Text("XY", style: TextStyle(fontSize: 12.0))),
            woodCutterMap[Surface.XY],
            SizedBox(height: 2 * blockLength),
            Padding(padding: EdgeInsets.all(5.0), child: Text("XZ", style: TextStyle(fontSize: 12.0))),
            woodCutterMap[Surface.XZ],
            SizedBox(height: 2 * blockLength),
            Padding(padding: EdgeInsets.all(5.0), child: Text("YZ", style: TextStyle(fontSize: 12.0))),
            woodCutterMap[Surface.YZ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MaterialButton(
                  child: Text("Forward"),
                  onPressed: () => _moveSaw(RelativeCoordinate.from(sawCoordinate, dy: 1))
                ), 
                MaterialButton(
                  child: Text("Backward"),
                  onPressed: () => _moveSaw(RelativeCoordinate.from(sawCoordinate, dy: -1))
                ), 
                MaterialButton(
                  child: Text("Right"),
                  onPressed: () => _moveSaw(RelativeCoordinate.from(sawCoordinate, dx: 1)),
                ), 
                MaterialButton(
                  child: Text("Left"),
                  onPressed: () => _moveSaw(RelativeCoordinate.from(sawCoordinate, dx: -1)),
                ), 
                MaterialButton(
                  child: Text("Up"),
                  onPressed: () => _moveSaw(RelativeCoordinate.from(sawCoordinate, dz: -1)),
                ), 
                MaterialButton(
                  child: Text("Down"),
                  onPressed: () => _moveSaw(RelativeCoordinate.from(sawCoordinate, dz: 1)),
                ), 
              ],
            )
          ],
        ),
      ),
    );
  }

  // Moving saw on all surfaces on current coordinate
  // `x` - new saw x coordinate
  // `y` - new saw y coordinate
  // `z` - new saw z coordinate
  moveSaw(int x, int y, int z) {
    _moveSaw(RelativeCoordinate(x: x, y: y, z: z));
  }

  // Moving saw on all surfaces on current relative coordinate
  // `coordinate` - new saw relative coordinate
  _moveSaw(RelativeCoordinate coordinate) {
    if (!inputLocked) {
      inputLocked = true;

      woodCutterMap.forEach((surface, woodCutter) {
        GlobalKey<WoodCutterState> key = woodCutter.key;
        
        Map<Axis, int> relativeAxisMap = coordinate.getAxes(surf: surface);
        int relativeX = relativeAxisMap[Axis.X];
        int relativeY = relativeAxisMap[Axis.Y];
        bool shouldCut = relativeAxisMap[Axis.Z] == 0;
        
        if (shouldCut) {
          _cutBlock(coordinate);
        }

        key.currentState.moveSaw(relativeX, relativeY, withCut: shouldCut);
      });

      _clearBlocksBehind(coordinate);

      sawCoordinate = coordinate;

      inputLocked = false;
    }
  }

  // Removing visually all blocks behind block if all blocks behind it is cutted 
  // `coordinate` - block coordinate
  _clearBlocksBehind(RelativeCoordinate coordinate) {
    woodCutterMap.forEach((surface, woodCutter) {
      GlobalKey<WoodCutterState> key = woodCutter.key;

      Map<Axis, int> relativeAxisMap = coordinate.getAxes(surf: surface);
      int relativeX = relativeAxisMap[Axis.X];
      int relativeY = relativeAxisMap[Axis.Y];

      if (!_hasBlocksBehind(coordinate, surface)) {
        key.currentState.clearBlocksBehind(relativeX, relativeY);
      }
    });
  }

  // Checking blocks existence behind current block 
  // `coordinate` - block relative coordinate
  // `surf` - visible surface of block
  bool _hasBlocksBehind(RelativeCoordinate coordinate, Surface surf) {
    return cuttedBlocks
      .where((block) => 
        block.getX(surf: surf) == coordinate.getX(surf: surf) 
        && block.getY(surf: surf) == coordinate.getY(surf: surf)
      )
      .length < axisLimits[surf.invisibleAxis];
  }

  // Removing block on current coordinate if it belong to bar limits
  // `coordinate` - block relative coordinate
  _cutBlock(RelativeCoordinate coordinate) {
    if (0 <= coordinate.getX() && coordinate.getX() <= axisLimits[Axis.X]
        && 0 <= coordinate.getY() && coordinate.getY() <= axisLimits[Axis.Y]
        && 0 <= coordinate.getZ() && coordinate.getZ() <= axisLimits[Axis.Z]) {
      cuttedBlocks.add(coordinate);
    }
  }
}