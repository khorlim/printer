import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:tunaipro/extra_utils/printer/model/custom_printer_model.dart';

class StarPrintManager {
  StarPrintManager._privateConstructor();

  static final StarPrintManager _instance =
      StarPrintManager._privateConstructor();

  factory StarPrintManager() {
    return _instance;
  }

  List<PortInfo>? _starPrinterPortList;

  final StreamController<String> _printerStatusController =
      StreamController<String>.broadcast();

  Stream<String> get printerStatusStream => _printerStatusController.stream;

  List<PortInfo> getStarPrinterList() {
    return _starPrinterPortList ?? [];
  }

  Future<List<PortInfo>> searchPrinter() async {
    try {
      _starPrinterPortList = await StarPrnt.portDiscovery(StarPortType.All);
      return _starPrinterPortList!;
    } catch (e) {
      debugPrintStack(maxFrames: 3);
      throw Exception('Failed to search star printer $e');
    }
  }

  Future<bool> getPrinterStatus(PortInfo port) async {
    try {
      final PrinterResponseStatus response = await StarPrnt.getStatus(
        portName: port.portName!,
        emulation: emulationFor(port.modelName!),
      );
      bool connected = !response.offline;
      return connected;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendPrintCommand(
      {required CustomPrinter printer, required PrintCommands commands}) async {
    try {
      final response = await StarPrnt.sendCommands(
          portName: printer.address,
          emulation: emulationFor(printer.name),
          printCommands: commands);
      bool isSuccess = response.isSuccess;
      return isSuccess;
    } catch (e) {
      throw Exception('Failed to send print command to printer. $e');
    }
  }

  String emulationFor(String modelName) {
    String emulation = 'StarGraphic';
    if (modelName != '') {
      final em = StarMicronicsUtilities.detectEmulation(modelName: modelName);
      emulation = em!.emulation!;
    }
    return emulation;
  }

  void _updatePrinterStatus(String status) {
    _printerStatusController.add(status);
  }

  void dispose() {
    _printerStatusController.close();
  }
}
