import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/port_scanner.dart';
import 'package:thermal_printer/thermal_printer.dart';

class NetworkPrintManager {
  static final NetworkPrintManager _instance = NetworkPrintManager._internal();

  factory NetworkPrintManager() {
    return _instance;
  }

  NetworkPrintManager._internal() {}

  Stream<TCPStatus> get statusStream => _networkDeviceStatusController.stream;
  Stream<List<PrinterDevice>> get networkDevicesStream =>
      _networkDevicesController.stream;

  TCPStatus _tCPStatus = TCPStatus.none;

  String _ipAddress = '';
  int _port = 9100;
  final String _subnet = '192.168.0';
  final Duration _timeout = const Duration(seconds: 5);
  Socket? _socket;

  StreamController<List<PrinterDevice>> _networkDevicesController =
      StreamController<List<PrinterDevice>>();
  StreamController<TCPStatus> _networkDeviceStatusController =
      StreamController<TCPStatus>();

  void searchPrinter() {
    List<PrinterDevice> networkDevicesList = [];
    final stream =
        PortScanner.discover(_subnet, _port, timeout: Duration(seconds: 7));
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

  // bool checkStatus() {
  //   if (_socket == null) {
  //     return false;
  //   }
  //   try {
  //     final InternetAddress address = _socket!.remoteAddress;
  //     debugPrint('-----> Already Connected to $address');
  //     return true;
  //   } catch (e) {
  //     _updateTCPStatus(TCPStatus.none);
  //     return false;
  //   }
  // }

  Future<bool> checkConnection(PrinterDevice selectedPrinter) async {
    debugPrint('-----> Connecting to address : ${selectedPrinter.address}');
    try {
      _ipAddress = selectedPrinter.address!;
      _socket = await Socket.connect(_ipAddress, _port, timeout: _timeout);

      _updateTCPStatus(TCPStatus.connected);
      await disconnect();
      debugPrint('-----> Can connect to address : ${selectedPrinter.address}');
      return true;
    } catch (e) {
      debugPrint(
          '-----> Failed to connect to address : ${selectedPrinter.address}');
      return false;
    }
  }

  Future<bool> realConnect(PrinterDevice selectedPrinter) async {
    debugPrint('-----> Connecting to address : ${selectedPrinter.address}');

    try {
      _ipAddress = selectedPrinter.address!;
      _socket = await Socket.connect(_ipAddress, _port, timeout: _timeout);
      _updateTCPStatus(TCPStatus.connected);
      debugPrint(
          '-----> Successfully connected to address : ${selectedPrinter.address}');
      return true;
    } catch (e) {
      debugPrint(
          '-----> Failed to connect to address : ${selectedPrinter.address}');
      return false;
    }
  }

  Future<bool> sendPrintCommand(List<int> bytes) async {
    // bool connected = checkStatus();
    try {
      bool connected = await realConnect(
          PrinterDevice(name: 'Local Device', address: _ipAddress));

      _socket!.add(Uint8List.fromList(bytes));
      await disconnect();

      return true;
    } catch (e) {
      debugPrintStack(maxFrames: 2);
      throw Exception('Failed to send command to printer. $e');
    }
  }

  Future<void> disconnect({Duration? timeout}) async {
    await _socket?.flush();
    await _socket?.close();
    _socket = null;
    return;
  }

  void _updateTCPStatus(TCPStatus status) {
    _tCPStatus = status;
    _networkDeviceStatusController.add(_tCPStatus);
  }
}
