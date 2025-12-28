import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  BleService._();
  static final BleService I = BleService._();

  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String DEVICE_NAME = "ESP32_Pulse";

  BluetoothDevice? _connectedDevice;
  
  // Real-time stream for the UI
  final _dataStreamController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  
  int? _cachedHeartRate;
  int? _cachedOxygen;
  int? _cachedSystolic;
  int? _cachedDiastolic;

  bool get isConnected => 
      _connectedDevice != null && _connectedDevice!.isConnected;

  Future<void> connect() async {
    if (isConnected) return;

    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Scan 15 seconds timeout
    print("BLE: Starting scan...");
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == DEVICE_NAME || r.device.name == DEVICE_NAME) {
          print("BLE: Found target device! Connecting...");
          await FlutterBluePlus.stopScan();
          await _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
    
      await device.connect(autoConnect: false); 
      _connectedDevice = device;

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print("BLE: Disconnected! Auto-reconnecting...");
          connect();
        }
      });
      
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var c in service.characteristics) {
            if (c.uuid.toString() == CHAR_UUID) {
              await c.setNotifyValue(true);
              
              c.lastValueStream.listen((value) {
                _parseData(value);
                // Send to stream for real-time UI
                _dataStreamController.add([
                  _cachedHeartRate ?? 0,
                  _cachedOxygen ?? 0,
                  _cachedSystolic ?? 0,
                  _cachedDiastolic ?? 0
                ]);
              });
              print("BLE: Listening for data...");
            }
          }
        }
      }
    } catch (e) {
      print("BLE Connection Error: $e");
    }
  }

  void _parseData(List<int> data) {
    String raw = String.fromCharCodes(data).trim();
    if (raw.isEmpty) return;
    
    if (raw.contains(',')) {
      var parts = raw.split(',');
      if (parts.length >= 4) { 
        int? hr = int.tryParse(parts[0].trim());
        int? ox = int.tryParse(parts[1].trim());
        int? sys = int.tryParse(parts[2].trim());
        int? dia = int.tryParse(parts[3].trim());

        if (hr != null && ox != null) {
          _cachedHeartRate = hr;
          _cachedOxygen = ox;
          _cachedSystolic = sys;
          _cachedDiastolic = dia;
        }
      } 
    }
  }

  
  int get heartRate => _cachedHeartRate ?? 0;
  int get oxygen => _cachedOxygen ?? 0;
  int get systolic => _cachedSystolic ?? 0;
  int get diastolic => _cachedDiastolic ?? 0;
  
  
  Future<int?> readHeartRate() async => _cachedHeartRate;
  Future<int?> readOxygen() async => _cachedOxygen;
  Future<int?> readSystolic() async => _cachedSystolic;
  Future<int?> readDiastolic() async => _cachedDiastolic;
}