import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:pius_lab1/service/web.dart';
import 'package:pius_lab1/widgets/woodCutterController.dart' as woodCutter;

class WoodCutterSimualtor extends StatefulWidget {
  static const MAX_TIME_MS = 10000;
  static final WEB_ADDRESS = GlobalConfiguration().getString("host");

  final Web web = Web();
  TextEditingController xBeginController;
  TextEditingController yBeginController;
  TextEditingController xEndController;
  TextEditingController yEndController;
  TextEditingController zEndController;
  TextEditingController timeController;

  TextEditingController addressController;

  // Initializing textfields' text holders
  WoodCutterSimualtor() {
    xBeginController = TextEditingController();
    yBeginController = TextEditingController();
    xEndController = TextEditingController();
    yEndController = TextEditingController();
    zEndController = TextEditingController();
    timeController = TextEditingController();

    addressController = TextEditingController();
  }

  // Initializing wood cutter simualtor state
  @override
  State<StatefulWidget> createState() => WoodCutterSimualtorState();
}

class WoodCutterSimualtorState extends State<WoodCutterSimualtor> {
  Map<TextEditingController, bool> errorMap;
  woodCutter.WoodCutterController woodCutterController;
  woodCutter.WoodCutterController getCurrentController() => woodCutterController;
  woodCutter.WoodCutterController setCurrentController(woodCutter.WoodCutterController controller) => woodCutterController = controller;

  bool isAuto = true;
  bool isPaused = false;
  bool isStopped = true;

  bool isStepProcessing = false;

  // Initializing textfields' text error map
  @override
  void initState() {
    super.initState();

    woodCutterController = woodCutter.WoodCutterController();

    errorMap = {
      widget.xBeginController: true,
      widget.yBeginController: true,
      widget.xEndController: true,
      widget.yEndController: true,
      widget.zEndController: true,
      widget.timeController: true
    };
  }

  // Draws wood cutter simulator on screen
  // `context` - context of visual widget tree
  @override
  Widget build(BuildContext context) {
    //woodCutterController.moveSaw(nextX, nextY, nextZ);
    String mode = isAuto
      ? "Автоматический режим"
      : "Ручной режим";

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Row(
          children: [
            Flexible(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(padding: EdgeInsets.all(5.0), child: Text(mode)),
                  SizedBox(height: 5.0),
                  _createTextField(widget.xBeginController, "Отступ по X", maxValue: woodCutterController.axisLimits[woodCutter.Axis.X] - 1),
                  _createTextField(widget.yBeginController, "Отступ по Y", maxValue: woodCutterController.axisLimits[woodCutter.Axis.Y] - 1),
                  SizedBox(height: 5.0),
                  _createTextField(widget.xEndController, "XMAX", maxValue: woodCutterController.axisLimits[woodCutter.Axis.X] - 1),
                  _createTextField(widget.yEndController, "YMAX", maxValue: woodCutterController.axisLimits[woodCutter.Axis.Y] - 1),
                  _createTextField(widget.zEndController, "ZMAX", maxValue: woodCutterController.axisLimits[woodCutter.Axis.Z] - 1),
                  SizedBox(height: 5.0),
                  _createTextField(widget.timeController, "TMAX", maxValue: WoodCutterSimualtor.MAX_TIME_MS, minValue: 1000),
                  _createTextField(widget.addressController, "Host"),
                  SizedBox(height: 5.0),
                  Row(
                    children: [
                      _createButton("Изменить паз", _webSetup),
                      _createButton("Пуск", _webStart),
                      _createButton("Пауза", _webPause),
                      _createButton("Стоп", _webExit),
                    ],
                  ),
                  SizedBox(height: 5.0),
                  Row(
                    children: [
                      _createButton("Авторежим", _webAuto),
                      _createButton("Ручной режим", _webManual),
                      _createButton("Шаг", _webNext),
                    ],
                  )
                ]
              ),
            ),
            SizedBox(width: 30.0),
            Flexible(
              flex: 1,
              child: woodCutterController,
            )
          ]
        ),
      )
    );
  }

  // Creating text field
  // `controller` - text holder
  // `name` - field name
  // `maxValue` - max number value of textfield
  Widget _createTextField(TextEditingController controller, String name, {int maxValue, int minValue}) {
    bool errorStatus = errorMap[controller];
    
    if (errorStatus != null) {
      if (maxValue != null) {
        name += " (от ${minValue ?? 0} до $maxValue)";
      } else {
        name += " (от ${minValue ?? 0})";
      }
    }

    return Padding(
      padding: EdgeInsets.all(5.0),
      child: TextField(
        controller: controller,
        onChanged: _getValidator(controller, maxValue: maxValue),
        decoration: InputDecoration(
          labelText: name,
          labelStyle: TextStyle(
            fontSize: 20,
            color: errorStatus != null && errorStatus ? Colors.red : Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  // Creating button with current listener
  // `name` - button visible name
  // `onTap` - function execting when button is pressed
  Widget _createButton(String name, Function onTap) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: MaterialButton(
        color: Colors.blueAccent,
        child: Text(name),
        onPressed: onTap,
      ),
    );
  }
  
  // Creates validator for textfield content
  // `controller` - textfield's text holder
  // `maxValue` - max number value of textfield
   void Function(String) _getValidator(TextEditingController controller, {int maxValue}) {
    return (valueStr) {
      if (errorMap.containsKey(controller)) {
        bool hasError = false;

        try {
          int value = int.parse(valueStr);

          if (value < 0 || (maxValue != null && value > maxValue)) {
            hasError = true;
          }
        } catch (error) {
          hasError = true;
        }

        setState(() => errorMap[controller] = hasError);
      }
    };
  }

  // Sending pazz setup to server
  _webSetup() {
    if (!errorMap.containsValue(true)) {
      Map<String, String> parameters = {
        "xBegin": widget.xBeginController.text,
        "yBegin": widget.yBeginController.text,
        "xEnd": widget.xEndController.text,
        "yEnd": widget.yEndController.text,
        "zEnd": widget.zEndController.text,
      };

      widget.web.get(widget.addressController.text, "/setup", parameters: parameters)
        .then((response) {
          if (response.status == 200) {
            setState(() {
              isStopped = false;
              isPaused = false;
            });
          }
        });
    }
  }

  // Sending start signal to server
  _webStart() {
    widget.web.get(widget.addressController.text, "/start")
      .then((response) {
        if (response.status == 200) {
          setState(() => isPaused = false);
          _webBlock();
        }
      });
  }

  // Sending pause signal to server
  _webPause() {
    widget.web.get(widget.addressController.text, "/pause")
      .then((response) => setState(() => isPaused = true));
  }

  // Sending stop signal to server
  _webExit() {
    widget.web.get(widget.addressController.text, "/stop")
      .then((response) => setState(() => isStopped = true));
  }

  // Sending auto mode signal to server. Simulator switching to auto mode
  _webAuto() {
    if (!errorMap[widget.timeController]) {
      widget.web.get(widget.addressController.text, "/auto", parameters: {"timeMs" : widget.timeController.text})
        .then((response) => setState(() => isAuto = true));
    }
  }

  // Sending manual mode signal to server. Simulator switching to manual mode
  _webManual() {
    if (isAuto) {
      widget.web.get(widget.addressController.text, "/manual")
        .then((response) => setState(() => isAuto = false));
    }
  }

  // Sending next signal to server. Allows recieving of next block in manual mode
  _webNext() async {
    if (!isAuto && !isStepProcessing) {
      isStepProcessing = true;
      await _webBlock();
      isStepProcessing = false;
    }
  }

  // Sending next block position to server 
  Future<bool> _webBlock() async {
    do {
      if (isPaused) {
        await new Future.delayed(Duration(milliseconds: 300));
        break;
      }

      widget.web.get(widget.addressController.text, "/block")
      .then((response) {
        print("/block STATUS: ${response.status}");

        if (response.status == 200) {
          try {
            _nextBlock(
              response.body["status"], 
              response.body["isAuto"], 
              response.body["setupChanged"], 
              response.body["x"], 
              response.body["y"],
              response.body["z"]
            );
          } catch (error) {}
        }
      })
      .catchError((error) {});

      var timeController = widget.timeController;
      try {
        if (errorMap[timeController]) {
          break;
        } else {
          await new Future.delayed(Duration(milliseconds: int.parse(timeController.text)));
        }
      } catch (error) { 
        break; 
      }
    } while(isAuto && !isStopped);

    return true;
  }

  // Moves saw to next block
  _nextBlock(String status, bool isAuto, bool isSetupChanged, int x, int y, int z) {
    if (status == "work") {
      print("MOVE SAW: $x $y $z");

      setState(() {
        isPaused = false;

        if (isSetupChanged) {
          woodCutterController.moveSaw(x, y, -1);
        }

        woodCutterController.moveSaw(x, y, z);
      });
    }

    if (status == "pause") {
      setState(() => isPaused = true);
    }

    if (status == "stopped") {
      setState(() => isStopped = true);
    }

    if (status == "noSetup") {
      setState(() => woodCutterController = woodCutter.WoodCutterController(sawX: 0, sawY: 0));
    }
  }
}