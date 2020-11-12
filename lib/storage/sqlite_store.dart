import 'package:WOLapp/models/machine_definition.dart';
import 'package:WOLapp/storage/machine_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteMachineStore implements MachineStore {
  Future<T> runWithDatabase<T>(Future<T> action(Database d)) async {
    final database = await openDatabase(join(await getDatabasesPath(), "wolmachines.db"),
        onCreate: (db, version) => db.execute(
            "CREATE TABLE machines(id INT PRIMARY KEY, caption TEXT, icon TEXT, macaddress TEXT, ipaddress TEXT, port INTEGER, password TEXT, color INTEGER);"),
        version: 1);
    final result = await action(database);
    await database.close();

    return result;
  }

  Future<List<MachineDefinition>> loadMachines() async {
    final dbResultList = await runWithDatabase((database) => database.rawQuery("SELECT * FROM machines"));
    return dbResultList.map(_machineFromDb).toList();
  }

  Future<void> storeMachines(List<MachineDefinition> machines) async {
    await runWithDatabase((database) => database.transaction((txn) async {
          await txn.execute("DELETE FROM machines");
          for (final MachineDefinition machine in machines) {
            txn.insert("machines", _machineToDb(machine));
          }
        }));
  }

  static MachineDefinition _machineFromDb(Map<String, dynamic> row) => new MachineDefinition(
      machineIndex: row["id"],
      caption: row["caption"],
      icon: row["icon"],
      color: _parseColor(row["color"]),
      macAddress: row["macaddress"],
      ipAddress: row["ipaddress"],
      port: row["port"],
      password: row["password"]);

  static Map<String, dynamic> _machineToDb(MachineDefinition machine) => {
        "id": machine.machineIndex,
        "caption": machine.caption,
        "icon": machine.icon,
        "color": machine.color?.value,
        "macaddress": machine.macAddress,
        "ipaddress": machine.ipAddress,
        "port": machine.port,
        "password": machine.password
      };

  static Color _parseColor(int dbColor) => dbColor == null ? null : Color(dbColor);
}
