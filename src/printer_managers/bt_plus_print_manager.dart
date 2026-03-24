import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';
import '../model/custom_printer_model.dart';
import 'universal_ble_print_chunks.dart';

class BtPlusPrintManager {
  static final BtPlusPrintManager _instance = BtPlusPrintManager._internal();
  BtPlusPrintManager._internal();
  factory BtPlusPrintManager() {
    return _instance;
  }

  /// One device per emission (unlike flutter_blue_plus aggregated lists).
  Stream<BleDevice> get scanStream => UniversalBle.scanStream;

  String? connectedDeviceId;

  Future<bool> getStatus(CustomPrinter printer) async {
    final state = await UniversalBle.getConnectionState(printer.address);
    return state == BleConnectionState.connected;
  }

  Future<void> startScan() async {
    debugPrint('bt plus start scan...');
    try {
      await UniversalBle.requestPermissions(withAndroidFineLocation: true);
      await UniversalBle.startScan(
        platformConfig: PlatformConfig(
          android: AndroidOptions(requestLocationPermission: true),
        ),
      );
      unawaited(Future<void>.delayed(const Duration(seconds: 8), () async {
        try {
          await UniversalBle.stopScan();
          debugPrint('bt plus stopped scan');
        } catch (e) {
          debugPrint('bt plus stop scan error: $e');
        }
      }));
    } catch (e) {
      debugPrint('bt plus start scan error: $e');
    }
  }

  Future<void> disconnect() async {
    final id = connectedDeviceId;
    if (id != null) {
      await UniversalBle.disconnect(id);
      connectedDeviceId = null;
    }
  }

  Future<bool> connectPrinter(CustomPrinter btDevice) async {
    try {
      await UniversalBle.connect(btDevice.address);
      connectedDeviceId = btDevice.address;
      return true;
    } catch (e) {
      debugPrint('bt plus failed to connect printer : $e');
      return false;
    }
  }

  Future<bool> sendPrintCommand(CustomPrinter printer, List<int> bytes) async {
    try {
      final device = BleDevice(deviceId: printer.address, name: printer.name);
      await device.connect();
      final maxPayload = await negotiatedMaxWritePayload(device);
      final services = await device.discoverServices();

      final target = pickThermalBleWriteTarget(services);
      if (target == null) {
        throw StateError(
          'No writable GATT characteristic on ${printer.name}. '
          'Firmware may use a non-standard BLE layout.',
        );
      }
      debugPrint(
        'BLE print: service=${target.serviceUuid} char=${target.characteristicUuid} '
        'withResponse=${target.withResponse} (${bytes.length} bytes)',
      );
      await writeBytesInAttChunks(
        target.characteristic,
        bytes,
        withResponse: target.withResponse,
        maxPayload: maxPayload,
        delayBetweenChunks: const Duration(milliseconds: 20),
      );

      return true;
    } catch (e, st) {
      debugPrintStack(stackTrace: st, maxFrames: 2);
      debugPrint('Failed to send command to printer. $e');
      throw Exception('Failed to send command to printer. $e');
    }
  }
}
