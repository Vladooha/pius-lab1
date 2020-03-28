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

  WoodCutterSimualtor() {
    xBeginController = TextEditingController();
    yBeginController = TextEditingController();
    xEndController = TextEditingController();
    yEndController = TextEditingController();
    zEndController = TextEditingController();
    timeController = TextEditingController();

    addressController = TextEditingController();
  }

  @override
  State<StatefulWidget> createState() => WoodCutterSimualtorState();
}

class WoodCutterSimualtorState extends State<WoodCutterSimualtor> {
  Map<TextEditingController, bool> errorMap;
  woodCutter.WoodCutterController woodCutterController;

  bool isAuto = true;
  bool isPaused = false;
  bool isStopped = true;

  bool isStepProcessing = false;

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

  @override
  Widget build(BuildContext context) {
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
                  _createTextField(widget.xBeginController, "Отступ по X", maxValue: woodCutterController.axisLimits[woodCutter.Axis.X]),
                  _createTextField(widget.yBeginController, "Отступ по Y", maxValue: woodCutterController.axisLimits[woodCutter.Axis.Y]),
                  SizedBox(height: 5.0),
                  _createTextField(widget.xEndController, "XMAX", maxValue: woodCutterController.axisLimits[woodCutter.Axis.X]),
                  _createTextField(widget.yEndController, "YMAX", maxValue: woodCutterController.axisLimits[woodCutter.Axis.Y]),
                  _createTextField(widget.zEndController, "ZMAX", maxValue: woodCutterController.axisLimits[woodCutter.Axis.Z]),
                  SizedBox(height: 5.0),
                  _createTextField(widget.timeController, "TMAX", maxValue: WoodCutterSimualtor.MAX_TIME_MS),
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

  Widget _createTextField(TextEditingController controller, String name, {int maxValue}) {
    bool errorStatus = errorMap[controller];
    
    if (errorStatus != null) {
      if (maxValue != null) {
        name += " (от 0 до $maxValue)";
      } else {
        name += " (от 0)";
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

  _webStart() {
    print("WoodCutter /start request...");
    widget.web.get(widget.addressController.text, "/start")
      .then((response) {
        if (response.status == 200) {
          print("WoodCutter /start 200 OK");
          setState(() => isPaused = false);
          _webBlock();
        }
      });
  }

  _webPause() {
    widget.web.get(widget.addressController.text, "/pause")
      .then((response) => setState(() => isPaused = true));
  }

  _webExit() {
    widget.web.get(widget.addressController.text, "/stop")
      .then((response) => setState(() => isStopped = true));
  }

  _webAuto() {
    if (!errorMap[widget.timeController]) {
      widget.web.get(widget.addressController.text, "/auto", parameters: {"timeMs" : widget.timeController.text})
        .then((response) => setState(() => isAuto = true));
    }
  }

  _webManual() {
    if (isAuto) {
      widget.web.get(widget.addressController.text, "/manual")
        .then((response) => setState(() => isAuto = false));
    }
  }

  _webNext() async {
    if (!isAuto && !isStepProcessing) {
      isStepProcessing = true;
      await _webBlock();
      isStepProcessing = false;
    }
  }

  Future<bool> _webBlock() async {
    print("WoodCutter /block request...");
    do {
      if (isPaused) {
        print("WoodCutter paused...");
        await new Future.delayed(Duration(milliseconds: 300));
        break;
      }

      widget.web.get(widget.addressController.text, "/block")
      .then((response) {
        print("WoodCutter /block response");
        
        if (response.status == 200) {
          print("WoodCutter /block 200 OK");

          try {
            _nextBlock(
              response.body["status"], 
              response.body["isAuto"].toLowerCase() == 'true', 
              response.body["setupChanged"].toLowerCase() == 'true', 
              int.parse(response.body["x"]), 
              int.parse(response.body["y"]),
              int.parse(response.body["z"])
            );
          } catch (error) {
            print(error);
          }
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

  _nextBlock(String status, bool isAuto, bool isSetupChanged, int x, int y, int z) {
    print("Block - status - $status, isAuto - $isAuto, isSetupChanged - $isSetupChanged, x - $x, y - $y, z - $z");

    if (status == "work") {
      if (isSetupChanged) {
        setState(() {
          isPaused = false;
          woodCutterController = woodCutter.WoodCutterController(sawX: x, sawY: y);
        });
      }

      print("Move saw on $x $y $z");
      woodCutterController.moveSaw(x, y, z);
    }

    if (status == "pause") {
      setState(() => isPaused = true);
    }

    if (status == "stopped") {
      setState(() => isStopped = true);
    }

    if (status == "noSetup") {
      setState(() => woodCutterController = null);
    }
  }
}