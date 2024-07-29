import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:thermal_printer/thermal_printer.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';

class BluetoothPrintManager {
  static final BluetoothPrintManager _instance =
      BluetoothPrintManager._internal();

  factory BluetoothPrintManager() {
    return _instance;
  }

  BluetoothPrintManager._internal() {
    _printerManager.stateBluetooth.listen((btStatus) {
      _btStatus = btStatus;
    });
  }

  final PrinterManager _printerManager = PrinterManager.instance;

  BTStatus _btStatus = BTStatus.none;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<PrinterDevice>? _searchSubscription;

  StreamController<List<PrinterDevice>> _btDevicesController =
      StreamController<List<PrinterDevice>>();

  Stream<BTStatus> get statusStream => _printerManager.stateBluetooth;
  Stream<List<PrinterDevice>> get btDeviceStream => _btDevicesController.stream;

  Future<bool> getStatus() async {
    await Future.delayed(Duration(seconds: 1));
    if (_btStatus == BTStatus.connected) {
      return true;
    } else {
      return false;
    }
  }

  void searchPrinter() async {
    try {
      List<PrinterDevice> btDevicesList = [];
      _searchSubscription = _printerManager
          .discovery(
        type: PrinterType.bluetooth,
      )
          .listen((device) {
        btDevicesList.add(device);
        _btDevicesController.add(btDevicesList);
      });
    } catch (e) {
      print('Failed to search for bluetooth devices. $e');
    }
  }

  Future<bool> connectPrinter(PrinterDevice selectedPrinter) async {
    try {
      // bool disconnected = await PrinterManager.instance.disconnect(
      //   type: PrinterType.bluetooth,
      // );
      bool connected = await PrinterManager.instance.connect(
          type: PrinterType.bluetooth,
          model: BluetoothPrinterInput(
            name: selectedPrinter.name,
            address: selectedPrinter.address!,
            autoConnect: true,
          ));
      await Future.delayed(Duration(milliseconds: 500));
      return _btStatus == BTStatus.connected;
    } catch (e) {
      return false;
      //   throw Exception('Failed to connect to bluetooth device. $e');
    }
  }

  Future<bool> sendPrintCommand(CustomPrinter printer, List<int> bytes) async {
    try {
      final List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.systemDevices;

      BluetoothDevice? foundConnectedDevice = connectedDevices
          .firstWhereOrNull((d) => d.remoteId.str == printer.address);

      if (foundConnectedDevice != null &&
          foundConnectedDevice.servicesList.isEmpty) {
        await foundConnectedDevice.connect();
        await foundConnectedDevice.discoverServices(
            subscribeToServicesChanged: false);
      }

      // print('max Mtu : $maxMtu');
      final BluetoothCharacteristic? character = foundConnectedDevice
          ?.servicesList.firstOrNull?.characteristics
          .firstWhereOrNull((element) => element.properties.write);

      if (character != null) {
        int maxWrite = 97;
        int totalBytes = bytes.length;
        int totalChunks = (totalBytes / maxWrite).ceil();

        for (int i = 0; i < totalChunks; i++) {
          int start = i * maxWrite;
          int end = (i + 1) * maxWrite;
          if (end > totalBytes) {
            end = totalBytes;
          }
          List<int> chunk = bytes.sublist(start, end);
          await character.write(chunk);
        }
      } else {
        bool sendSuccess = await _printerManager.send(
            type: PrinterType.bluetooth, bytes: bytes);
        return sendSuccess;
      }

      return true;
    } catch (e) {
      debugPrintStack(maxFrames: 2);
      print(e);
      throw Exception('Failed to send command to printer. $e');
    }
  }

  void dispose() {
    _subscriptionBtStatus?.cancel();
    _searchSubscription?.cancel();
  }
}
