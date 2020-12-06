import 'dart:io';

import 'package:WOLapp/models/machine_definition.dart';
import 'package:WOLapp/packet_sender.dart';
import 'package:WOLapp/storage/machine_store.dart';
import 'package:WOLapp/storage/sqlite_store.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp reMacAddress = RegExp(
    r'^((([0-9A-F]{2}-){5}[0-9A-F]{2})|(([0-9A-F]{2}:){5}[0-9A-F]{2}))$',
    caseSensitive: false);

final MachineStore machineStore = new SqliteMachineStore();
PackageInfo packageInfo;

void main() async {
  runApp(WolApp());
}

class WolApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (packageInfo == null) {
      PackageInfo.fromPlatform().then((value) => packageInfo = value);
    }
    return MaterialApp(
      title: 'WOLApp',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
  List<MachineDefinition> _machineDefinitions;

  _MachineSelectionListState() {
    machineStore.loadMachines().then(_loadedFromDb);
  }

  void _loadedFromDb(List<MachineDefinition> definitions) {
    setState(() {
      _machineDefinitions = definitions;
    });
  }

  void _editMachine(BuildContext context, MachineDefinition definition) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => MachineEditForm(
          definition,
          onSave: _saveModifiedDefinition,
          onDelete: _deleteMachine),
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
      machineStore.storeMachines(_machineDefinitions);
    });
  }

  void _deleteMachine(int deletedMachine) {
    setState(() {
      _machineDefinitions.removeAt(deletedMachine);
      machineStore.storeMachines(_machineDefinitions);
    });
  }

  static void _launchURL(String url) async {
    if (true || await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("WOLApp"),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text('WOL App'),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                      context: context,
                      applicationName: "WOL App",
                      applicationVersion: packageInfo.version,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () =>
                              launch("https://github.com/mormegil-cz/wolapp"),
                          child: Text("GitHub"),
                        ),
                      ]);
                },
              )
            ],
          ),
        ),
        body: _machineDefinitions == null
            ? Center(child: CircularProgressIndicator())
            : _machineDefinitions.isEmpty
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
                          .map((machine) => MachineListTile(
                              machine: machine, onTap: _editMachine))
                          .toList(growable: false),
                    ),
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              {_editMachine(context, new MachineDefinition(machineIndex: -1))},
          tooltip: 'Add new machine',
          child: Icon(Icons.add),
        ),
      );
}

class MachineListTile extends StatelessWidget {
  final MachineDefinition machine;
  final void Function(BuildContext buildContext, MachineDefinition machine)
      onTap;

  const MachineListTile({Key key, this.machine, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(machine.getIcon(),
            color:
                machine.color ?? Theme.of(context).textTheme.bodyText2.color),
        title: Text(machine.getCaption()),
        trailing: IconButton(
          icon:
              Icon(Icons.power_settings_new, semanticLabel: "Send wake packet"),
          onPressed: () async {
            try {
              await sendWakeUpPacket(machine.macAddress, machine.ipAddress,
                  machine.port, machine.password);
              Scaffold.of(context).showSnackBar(SnackBar(
                  content:
                      Text("Wakeup packet for ${machine.getCaption()} sent")));
            } catch (e) {
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text("Error sending wakeup packet"),
                  backgroundColor: Colors.redAccent));
            }
          },
        ),
        onTap: () {
          this.onTap(context, machine);
        },
      );
}

class MachineEditForm extends StatefulWidget {
  final MachineDefinition definition;
  final void Function(MachineDefinition definition) onSave;
  final void Function(int machineIndex) onDelete;

  MachineEditForm(this.definition, {this.onSave, this.onDelete});

  @override
  _MachineEditFormState createState() =>
      _MachineEditFormState(definition, onSave: onSave, onDelete: onDelete);
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

  _MachineEditFormState(MachineDefinition definition,
      {this.onSave, this.onDelete})
      : _editedIndex = definition.machineIndex,
        _ctrlCaption = TextEditingController(text: definition.caption),
        _ctrlMacAddress = TextEditingController(text: definition.macAddress),
        _ctrlIpAddress = TextEditingController(
            text: definition.ipAddress ?? "255.255.255.255"),
        _ctrlPortNumber =
            TextEditingController(text: definition.port?.toString() ?? "9"),
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
        title: Text(_editedIndex < 0
            ? "WOLApp: Add new machine"
            : "WOLApp: Edit machine"),
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
    if (parsedPort < 0 || parsedPort > 65535)
      return 'Enter a valid port between 0 and 65535';
    return null;
  }
}
