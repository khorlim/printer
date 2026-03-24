import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:thermal_printer/thermal_printer.dart';
import 'package:universal_ble/universal_ble.dart';
import '../model/custom_printer_model.dart';
import 'universal_ble_print_chunks.dart';

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
      await PrinterManager.instance.connect(
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
    }
  }

  Future<void> disconnect() async {
    await PrinterManager.instance.disconnect(
      type: PrinterType.bluetooth,
    );
  }

  Future<bool> sendPrintCommand(CustomPrinter printer, List<int> bytes) async {
    try {
      final systemDevices = await UniversalBle.getSystemDevices();
      BleDevice? foundConnectedDevice = systemDevices
          .firstWhereOrNull((d) => d.deviceId == printer.address);

      if (foundConnectedDevice != null) {
        if (!await foundConnectedDevice.isConnected) {
          await foundConnectedDevice.connect();
        }
        final maxPayload = await negotiatedMaxWritePayload(
          foundConnectedDevice,
        );
        final services = await foundConnectedDevice.discoverServices();

        final target = pickThermalBleWriteTarget(services);
        if (target != null) {
          debugPrint(
            'BLE print (classic BT path): service=${target.serviceUuid} '
            'char=${target.characteristicUuid} withResponse=${target.withResponse}',
          );
          await writeBytesInAttChunks(
            target.characteristic,
            bytes,
            withResponse: target.withResponse,
            maxPayload: maxPayload,
            delayBetweenChunks: const Duration(milliseconds: 20),
          );
          return true;
        }
      }

      final bool sendSuccess = await _printerManager.send(
          type: PrinterType.bluetooth, bytes: bytes);
      return sendSuccess;
    } catch (e, st) {
      debugPrintStack(stackTrace: st, maxFrames: 2);
      print(e);
      throw Exception('Failed to send command to printer. $e');
    }
  }

  void dispose() {
    _subscriptionBtStatus?.cancel();
    _searchSubscription?.cancel();
  }
}
