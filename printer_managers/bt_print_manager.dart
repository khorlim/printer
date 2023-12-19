import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:thermal_printer/thermal_printer.dart';

class BluetoothPrintManager {
  BluetoothPrintManager._();

  static final BluetoothPrintManager _instance = BluetoothPrintManager._();

  static BluetoothPrintManager get instance => _instance;

  final PrinterManager _printerManager = PrinterManager.instance;
  BTStatus _currentStatus = BTStatus.none;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<PrinterDevice>? _searchSubscription;

  StreamController<List<PrinterDevice>> _btDevicesController =
      StreamController<List<PrinterDevice>>();

  Stream<BTStatus> get statusStream => _printerManager.stateBluetooth;
  Stream<List<PrinterDevice>> get btDeviceStream => _btDevicesController.stream;

  BluetoothPrintManager() {
    _subscriptionBtStatus = _printerManager.stateBluetooth.listen((status) {
      log(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;
      if (status == BTStatus.connected) {}
      if (status == BTStatus.none) {}
      // if (status == BTStatus.connected && pendingTask != null) {
      //   if (Platform.isAndroid) {
      //     Future.delayed(const Duration(milliseconds: 1000), () {
      //       PrinterManager.instance
      //           .send(type: PrinterType.bluetooth, bytes: pendingTask!);
      //       pendingTask = null;
      //     });
      //   } else if (Platform.isIOS) {
      //     PrinterManager.instance
      //         .send(type: PrinterType.bluetooth, bytes: pendingTask!);
      //     pendingTask = null;
      //   }
      // }
    });
  }

  BTStatus getStatus() {
    return _currentStatus;
  }

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
              isBle: false,
              autoConnect: true));
      return connected;
    } catch (e) {
      debugPrintStack();
      throw Exception('Failed to connect to bluetooth device. $e');
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
