import 'dart:io';

import 'package:WOLapp/models/machine_definition.dart';
import 'package:WOLapp/packet_sender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

final RegExp reMacAddress =
    RegExp(r'^((([0-9A-F]{2}-){5}[0-9A-F]{2})|(([0-9A-F]{2}:){5}[0-9A-F]{2}))$', caseSensitive: false);

void main() {
  runApp(WolApp());
}

class WolApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'WOLApp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MachineSelectionList(),
      );
}

class MachineSelectionList extends StatefulWidget {
  MachineSelectionList({Key key}) : super(key: key);

  @override
  _MachineSelectionListState createState() => _MachineSelectionListState();
}

class _MachineSelectionListState extends State<MachineSelectionList> {
  final List<MachineDefinition> _machineDefinitions = [
    new MachineDefinition(
        machineIndex: 0,
        macAddress: "12:34:56:78:9A:BC",
        caption: "Server",
        ipAddress: "255.255.255.255",
        port: 9)
  ];

  void _editMachine(BuildContext context, MachineDefinition definition) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          MachineEditForm(definition, onSave: _saveModifiedDefinition, onDelete: _deleteMachine),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ));
  }

  void _saveModifiedDefinition(MachineDefinition definition) {
    setState(() {
      if (definition.machineIndex < 0) {
        definition.machineIndex = _machineDefinitions.length;
        _machineDefinitions.add(definition);
      } else {
        _machineDefinitions[definition.machineIndex] = definition;
      }
    });
  }

  void _deleteMachine(int deletedMachine) {
    setState(() {
      _machineDefinitions.removeAt(deletedMachine);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("WOLApp"),
        ),
        body: _machineDefinitions.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("No machines defined!"),
                  Text("Press the button to add a first one!"),
                ]),
              )
            : Scrollbar(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _machineDefinitions
                      .map((machine) => ListTile(
                            leading: Icon(machine.getIcon(),
                                color: machine.color ?? Theme.of(context).textTheme.bodyText2.color),
                            title: Text(machine.getCaption()),
                            trailing: IconButton(
                              icon: Icon(Icons.power_settings_new, semanticLabel: "Send wake packet"),
                              onPressed: () async {
                                try {
                                  await sendWakeUpPacket(
                                      machine.macAddress, machine.ipAddress, machine.port, machine.password);
                                  Fluttertoast.showToast(msg: "Wakeup packet sent");
                                } catch (e) {
                                  Fluttertoast.showToast(
                                      msg: "Error sending wakeup packet", backgroundColor: Colors.redAccent);
                                }
                              },
                            ),
                            onTap: () {
                              _editMachine(context, machine);
                            },
                          ))
                      .toList(growable: false),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => {_editMachine(context, new MachineDefinition(machineIndex: -1))},
          tooltip: 'Add new machine',
          child: Icon(Icons.add),
        ),
      );
}

class MachineEditForm extends StatefulWidget {
  final MachineDefinition definition;
  final void Function(MachineDefinition definition) onSave;
  final void Function(int machineIndex) onDelete;

  MachineEditForm(this.definition, {this.onSave, this.onDelete});

  @override
  _MachineEditFormState createState() => _MachineEditFormState(definition, onSave: onSave, onDelete: onDelete);
}

class _MachineEditFormState extends State<MachineEditForm> {
  final _formKey = GlobalKey<FormState>();

  final void Function(MachineDefinition definition) onSave;
  final void Function(int machineIndex) onDelete;

  final int _editedIndex;
  final TextEditingController _ctrlCaption;
  final TextEditingController _ctrlMacAddress;
  final TextEditingController _ctrlIpAddress;
  final TextEditingController _ctrlPortNumber;
  final TextEditingController _ctrlPassword;

  _MachineEditFormState(MachineDefinition definition, {this.onSave, this.onDelete})
      : _editedIndex = definition.machineIndex,
        _ctrlCaption = TextEditingController(text: definition.caption),
        _ctrlMacAddress = TextEditingController(text: definition.macAddress),
        _ctrlIpAddress = TextEditingController(text: definition.ipAddress ?? "255.255.255.255"),
        _ctrlPortNumber = TextEditingController(text: definition.port?.toString() ?? "9"),
        _ctrlPassword = TextEditingController(text: definition.password);

  @override
  void dispose() {
    _ctrlCaption.dispose();
    _ctrlMacAddress.dispose();
    _ctrlIpAddress.dispose();
    _ctrlPortNumber.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(_editedIndex < 0 ? "WOLApp: Add new machine" : "WOLApp: Edit machine"),
        actions: [
          if (_editedIndex >= 0)
            IconButton(
                icon: Icon(Icons.delete),
                tooltip: "Delete",
                onPressed: () {
                  onDelete(_editedIndex);
                  Navigator.pop(context);
                }),
          IconButton(
              icon: Icon(Icons.check),
              tooltip: "Save changes",
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  onSave(new MachineDefinition(
                    machineIndex: _editedIndex,
                    caption: _ctrlCaption.text,
                    macAddress: _ctrlMacAddress.text,
                    ipAddress: _ctrlIpAddress.text,
                    port: int.parse(_ctrlPortNumber.text),
                    password: _ctrlPassword.text,
                    // TODO: icon, color
                  ));
                  Navigator.pop(context);
                }
              }),
        ],
      ),
      body: Form(
          key: _formKey,
          child: ListView(children: [
            ListTile(
              title: TextFormField(
                decoration: InputDecoration(labelText: 'Caption'),
                controller: _ctrlCaption,
                autocorrect: true,
                autofocus: true,
              ),
            ),
            ListTile(
              title: TextFormField(
                decoration: InputDecoration(labelText: 'MAC Address'),
                controller: _ctrlMacAddress,
                validator: _validateMacAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.visiblePassword,
              ),
            ),
            ListTile(
              title: TextFormField(
                decoration: InputDecoration(labelText: 'IP Address'),
                controller: _ctrlIpAddress,
                validator: _validateIpAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
              ),
            ),
            ListTile(
              title: TextFormField(
                decoration: InputDecoration(labelText: 'Port number'),
                controller: _ctrlPortNumber,
                validator: _validatePortNumber,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
              ),
            ),
            ListTile(
              title: TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                controller: _ctrlPassword,
                obscureText: true,
              ),
            ),
          ])));

  static String _validateMacAddress(String value) {
    if (value.isEmpty) return 'This is a required field';
    if (!reMacAddress.hasMatch(value)) return 'Enter a valid MAC address';
    return null;
  }

  static String _validateIpAddress(String value) {
    if (value.isEmpty) return 'This is a required field';
    try {
      InternetAddress(value);
    } catch (e) {
      return 'Enter a valid IP address';
    }
    return null;
  }

  static String _validatePortNumber(String value) {
    if (value.isEmpty) return 'This is a required field';
    final parsedPort = int.tryParse(value);
    if (parsedPort == null) return 'Enter a valid port number';
    if (parsedPort < 0 || parsedPort > 65535) return 'Enter a valid port between 0 and 65535';
    return null;
  }
}
