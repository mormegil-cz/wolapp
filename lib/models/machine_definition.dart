import 'package:WOLapp/iconset.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class MachineDefinition {
  final String caption;
  final String icon;
  final String macAddress;
  final String ipAddress;
  final int port;
  final String password;
  final Color color;

  MachineDefinition({this.caption, this.icon, this.color, @required this.macAddress, @required this.ipAddress, @required this.port, this.password});

  IconData getIcon() => iconDefinitions[icon ?? DEFAULT_ICON] ?? iconDefinitions[DEFAULT_ICON];

  String getCaption() => caption ?? macAddress;
}
