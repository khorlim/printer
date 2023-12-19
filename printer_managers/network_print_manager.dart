import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:printer_test/printer/utils/port_scanner.dart';
import 'package:thermal_printer/thermal_printer.dart';

class NetworkPrintManager {
  static final NetworkPrintManager _instance = NetworkPrintManager._internal();

  factory NetworkPrintManager() {
    return _instance;
  }

  NetworkPrintManager._internal() {
    //  PrinterManager.instance.stateUSB is only supports on Android
    _subscriptionTCPStatus = PrinterManager.instance.stateTCP.listen((status) {
      log(' ----------------- status tcp $status ------------------ ');
      _currentTCPStatus = status;
    });
  }

  final PrinterManager _printerManager = PrinterManager.instance;
  TCPStatus _currentTCPStatus = TCPStatus.none;
  StreamSubscription<TCPStatus>? _subscriptionTCPStatus;
  StreamSubscription<PrinterDevice>? _searchSubscription;
  String _ipAddress = '';
  String _port = '9100';
  String _subnet = '192.168.0';

  StreamController<List<PrinterDevice>> _networkDevicesController =
      StreamController<List<PrinterDevice>>();

  Stream<TCPStatus> get statusStream => PrinterManager.instance.stateTCP;
  Stream<List<PrinterDevice>> get networkDevicesStream =>
      _networkDevicesController.stream;

  void searchPrinter() {
    List<PrinterDevice> networkDevicesList = [];
    final stream = PortScanner.discover(_subnet, int.parse(_port),
        timeout: Duration(seconds: 7));
    stream.listen((networkAddress) {
      networkDevicesList.add(PrinterDevice(
          name: 'Local device (${networkAddress.ip} : $_port)',
          address: networkAddress.ip));
      _networkDevicesController.add(networkDevicesList);
    });
    // _searchSubscription = _printerManager
    //     .discovery(
    //   type: PrinterType.network,
    //   model: TcpPrinterInput(ipAddress: )
    // )
    //     .listen((device) {
    //   networkDevicesList.add(device);
    //   _networkDevicesController.add(networkDevicesList);
    // });
  }

  Future<bool> connectPrinter(PrinterDevice selectedPrinter) async {
    print('Connecting to address : ${selectedPrinter.address}');
    try {
      bool connectedTCP = await _printerManager.connect(
          type: PrinterType.network,
          model: TcpPrinterInput(ipAddress: selectedPrinter.address!));

      if (!connectedTCP) print(' --- please review your connection ---');
      return connectedTCP;
    } catch (e) {
      debugPrintStack();
      throw Exception('Failed to connect to network device. $e');
    }
  }

  Future<bool> sendPrintCommand(List<int> bytes) async {
    try {
      bool sendSuccess =
          await _printerManager.send(type: PrinterType.network, bytes: bytes);
      return sendSuccess;
    } catch (e) {
      debugPrintStack(maxFrames: 2);
      throw Exception('Failed to send command to printer. $e');
    }
  }

  void dispose() {
    _subscriptionTCPStatus?.cancel();
    _searchSubscription?.cancel();
  }
}
