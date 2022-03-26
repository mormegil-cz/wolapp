import 'package:flutter/material.dart';
import 'package:wol_app/iconset.dart';

class MachineDefinition {
  int machineIndex;
  final String? caption;
  final String? icon;
  final String? macAddress;
  final String? ipAddress;
  final int? port;
  final String? password;
  final Color? color;

  MachineDefinition({required this.machineIndex, this.caption, this.icon, this.color, this.macAddress, this.ipAddress, this.port, this.password});

  IconData getIcon() => iconDefinitions[icon ?? DEFAULT_ICON] ?? iconDefinitions[DEFAULT_ICON]!;

  String? getCaption() => caption ?? macAddress;
}
