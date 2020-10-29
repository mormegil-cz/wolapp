import 'package:WOLapp/iconset.dart';
import 'package:WOLapp/models/machine_definition.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(WolApp());
}

class WolApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WOLApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MachineSelectionList(),
    );
  }
}

class MachineSelectionList extends StatefulWidget {
  MachineSelectionList({Key key}) : super(key: key);

  @override
  _MachineSelectionListState createState() => _MachineSelectionListState();
}

class _MachineSelectionListState extends State<MachineSelectionList> {
  final List<MachineDefinition> _machineDefinitions = [
    new MachineDefinition(
        macAddress: "12:34:56:78:9A:BC",
        caption: "Server",
        ipAddress: "192.168.123.255",
        port: 9)
  ];

  void _addNewMachine() {
    setState(() {
      _machineDefinitions.add(new MachineDefinition(
          macAddress: "12:34:56:78:9A:BC",
          caption: "Server " + _machineDefinitions.length.toString(),
          ipAddress: "192.168.123.255",
          port: 9,
          icon: iconDefinitions.keys
              .elementAt(_machineDefinitions.length % iconDefinitions.length)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WOLApp"),
      ),
      body: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: _machineDefinitions
              .map((machine) => ListTile(
                    leading: Icon(machine.getIcon(),
                        color: machine.color ?? Theme.of(context).textTheme.bodyText2.color),
                    title: Text(machine.getCaption()),
                    trailing: Icon(Icons.power_settings_new),
                  ))
              .toList(growable: false),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMachine,
        tooltip: 'Add new machine',
        child: Icon(Icons.add),
      ),
    );
  }
}
