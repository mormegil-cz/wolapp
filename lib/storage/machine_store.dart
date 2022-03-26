import 'package:wol_app/models/machine_definition.dart';

abstract class MachineStore {
  Future<List<MachineDefinition>> loadMachines();

  Future<void> storeMachines(Iterable<MachineDefinition> machines);

  Future<String> exportMachinesJson();

  Future<void> importMachinesJson(String importJson);
}
