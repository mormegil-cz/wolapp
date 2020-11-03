import 'package:WOLapp/models/machine_definition.dart';
import 'package:WOLapp/packet_sender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
        ipAddress: "255.255.255.255",
        port: 9)
  ];

  void _addNewMachine(BuildContext context) {
    Navigator.of(context).push(new PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => new MachineEditForm(),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("WOLApp"),
        ),
        body: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _machineDefinitions
                .map((machine) => ListTile(
                      leading:
                          Icon(machine.getIcon(), color: machine.color ?? Theme.of(context).textTheme.bodyText2.color),
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
                        Fluttertoast.showToast(msg: "detail");
                      },
                    ))
                .toList(growable: false),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => {_addNewMachine(context)},
          tooltip: 'Add new machine',
          child: Icon(Icons.add),
        ),
      );
}

class MachineEditForm extends StatefulWidget {
  @override
  _MachineEditFormState createState() {
    return _MachineEditFormState();
  }
}

class _MachineEditFormState extends State<MachineEditForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text("WOLApp: Add new machine"),
      ),
      body: Form(
          key: _formKey,
          child: Column(children: <Widget>[
            TextFormField(
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              decoration: InputDecoration(
                  labelText: 'Enter your username'
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Navigator.pop(context);
                }
              },
              child: Text('Submit'),
            )
          ])));
}
