import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(MaterialApp(
    home: BluetoothHC05Control(),
    debugShowCheckedModeBanner: false,
  ));
}

class BluetoothHC05Control extends StatefulWidget {
  const BluetoothHC05Control({super.key});

  @override
  _BluetoothHC05ControlState createState() => _BluetoothHC05ControlState();
}

class _BluetoothHC05ControlState extends State<BluetoothHC05Control> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() => _bluetoothState = state);
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() => _bluetoothState = state);
    });

    _getPairedDevices();
  }

  List<BluetoothDevice> _devicesList = [];

  void _getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print('Error getting bonded devices: $e');
    }
    setState(() {
      _devicesList = devices;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() => _isButtonUnavailable = true);
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to the device');
      setState(() {
        _device = device;
        _connection = connection;
        _connected = true;
      });
    } catch (e) {
      print('Cannot connect: $e');
    }
    setState(() => _isButtonUnavailable = false);
  }

  void _sendCommand(String command) {
    if (_connection != null && _connected) {
      _connection!.output.add(Uint8List.fromList(command.codeUnits));
      print("Sent: $command");
    }
  }

  @override
  void dispose() {
    if (_connected) {
      _connection?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kontrol HC-05 via Bluetooth"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<BluetoothDevice>(
              hint: Text("Pilih HC-05"),
              value: _device,
              onChanged: _connected ? null : (device) => _connectToDevice(device!),
              items: _devicesList
                  .map((device) => DropdownMenuItem(
                        value: device,
                        child: Text(device.name ?? device.address),
                      ))
                  .toList(),
            ),
            SizedBox(height: 20),
            if (_connected)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _sendCommand("UP\n"),
                    child: Icon(Icons.arrow_upward),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _sendCommand("LEFT\n"),
                        child: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => _sendCommand("RIGHT\n"),
                        child: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _sendCommand("DOWN\n"),
                    child: Icon(Icons.arrow_downward),
                  ),
                ],
              ),
            if (!_connected && !_isButtonUnavailable)
              Text("Pilih HC-05 dari daftar perangkat yang dipasangkan."),
            if (_isButtonUnavailable)
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
