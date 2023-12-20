import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:thermal_printer/thermal_printer.dart';

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
  BTStatus get cuurentStatus => _btStatus;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<PrinterDevice>? _searchSubscription;

  StreamController<List<PrinterDevice>> _btDevicesController =
      StreamController<List<PrinterDevice>>();

  Stream<BTStatus> get statusStream => _printerManager.stateBluetooth;
  Stream<List<PrinterDevice>> get btDeviceStream => _btDevicesController.stream;

  void searchPrinter() {
    List<PrinterDevice> btDevicesList = [];
    _searchSubscription = _printerManager
        .discovery(
      type: PrinterType.bluetooth,
    )
        .listen((device) {
      btDevicesList.add(device);
      _btDevicesController.add(btDevicesList);
    });
  }

  Future<bool> connectPrinter(PrinterDevice selectedPrinter) async {
    try {
      bool connected = await PrinterManager.instance.connect(
          type: PrinterType.bluetooth,
          model: BluetoothPrinterInput(
            name: selectedPrinter.name,
            address: selectedPrinter.address!,
          ));
      await Future.delayed(Duration(milliseconds: 500));
      return _btStatus == BTStatus.connected;
    } catch (e) {
      return false;
      //   throw Exception('Failed to connect to bluetooth device. $e');
    }
  }

  Future<bool> sendPrintCommand(List<int> bytes) async {
    try {
      bool sendSuccess =
          await _printerManager.send(type: PrinterType.bluetooth, bytes: bytes);
      return sendSuccess;
    } catch (e) {
      debugPrintStack(maxFrames: 2);
      throw Exception('Failed to send command to printer. $e');
    }
  }

  void dispose() {
    _subscriptionBtStatus?.cancel();
    _searchSubscription?.cancel();
  }
}
