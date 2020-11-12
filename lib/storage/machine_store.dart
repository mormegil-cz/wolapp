import 'package:WOLapp/models/machine_definition.dart';

abstract class MachineStore {
  Future<List<MachineDefinition>> loadMachines();
  Future<void> storeMachines(List<MachineDefinition> machines);
}
