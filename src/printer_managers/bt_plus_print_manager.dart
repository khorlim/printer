import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/theme/style_imports.dart';

class BtPlusPrintManager {
  static final BtPlusPrintManager _instance = BtPlusPrintManager._internal();
  BtPlusPrintManager._internal();
  factory BtPlusPrintManager() {
    return _instance;
  }
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  Stream<List<ScanResult>> get scanStream => FlutterBluePlus.onScanResults;
  BluetoothDevice? connectedDevice;

  Future<bool> getStatus() async {
    return true;
  }

  void init() {
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        // print('scanned results : $results');
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          r.device.connect();
          // print(
          //     'newest : ${r.device.remoteId}: "${r.advertisementData.advName}" found!');
        }
      },
      onError: (e) => print(e),
    );
  }

  void startScan() async {
    return await FlutterBluePlus.startScan(
      // withMsd: [
      //   MsdFilter(manufacturerId)
      // ],
      // withServices: [Guid("180D")], // match any of the specified services
      // withNames: ["Bluno"], // *or* any of the specified names
      timeout: Duration(seconds: 5),
    );
  }

  Future<bool> connectPrinter(CustomPrinter btDevice) async {
    try {
      await BluetoothDevice.fromId(btDevice.address).connect();
      return true;
    } catch (e) {
      print('bt plus failed to connect printer : $e');
      return false;
      //   throw Exception('Failed to connect to bluetooth device. $e');
    }
  }

  Future<bool> sendPrintCommand(CustomPrinter printer, List<int> bytes) async {
    try {
      BluetoothDevice foundConnectedDevice =
          BluetoothDevice.fromId(printer.address);

      await foundConnectedDevice.connect();
      await foundConnectedDevice.discoverServices(
          subscribeToServicesChanged: false);

      // print('max Mtu : $maxMtu');
      final BluetoothCharacteristic? character = foundConnectedDevice
          .servicesList.firstOrNull?.characteristics
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
      }

      return true;
    } catch (e) {
      debugPrintStack(maxFrames: 2);
      print(e);
      throw Exception('Failed to send command to printer. $e');
    }
  }
}
