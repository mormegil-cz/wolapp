import 'package:WOLapp/iconset.dart';
import 'package:flutter/material.dart';

class MachineDefinition {
  int machineIndex;
  final String caption;
  final String icon;
  final String macAddress;
  final String ipAddress;
  final int port;
  final String password;
  final Color color;

  MachineDefinition({this.machineIndex, this.caption, this.icon, this.color, this.macAddress, this.ipAddress, this.port, this.password});

  IconData getIcon() => iconDefinitions[icon ?? DEFAULT_ICON] ?? iconDefinitions[DEFAULT_ICON];

  String getCaption() => caption ?? macAddress;
}
