import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:pius_lab1/widgets/woodCutterSimulator.dart';

void main() async {
  GlobalConfiguration().loadFromAsset("web");
  runApp(WoodCutterSimualtor());
} 

