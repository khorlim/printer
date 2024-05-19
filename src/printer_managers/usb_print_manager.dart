import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:thermal_printer/thermal_printer.dart';
import 'package:quick_usb/quick_usb.dart';

class UsbPrintManager {
  static final UsbPrintManager _instance = UsbPrintManager._internal();

  factory UsbPrintManager() {
    return _instance;
  }

  UsbPrintManager._internal();

  final PrinterManager printerManager = PrinterManager.instance;

  Stream<List<PrinterDevice>> get usbDevicesStream =>
      _usbDevicesController.stream;
  final StreamController<List<PrinterDevice>> _usbDevicesController =
      StreamController<List<PrinterDevice>>.broadcast();

  List<PrinterDevice> _usbDevices = [];

  void searchPrinter() async {
    _usbDevices.clear();
    _usbDevicesController.add(_usbDevices);
    final subs =
        printerManager.discovery(type: PrinterType.usb).listen((device) {
         
      // print(
      //     'Found usb device : ${device.name}, ${device.address}, ${device.operatingSystem} , ${device.productId}, ${device.vendorId}');
      _usbDevices.add(device);
      _usbDevicesController.add(_usbDevices);
    });

    await Future.delayed(Duration(seconds: 5));
    subs.cancel();
  }

  Future<bool> checkConnection(PrinterDevice device) async {
    
    try {
      bool connected = await printerManager.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
              name: device.name,
              productId: device.productId,
              vendorId: device.vendorId));


      return connected;
    } catch (e) {
      print(
          'Failed to check usb printer(${device.name}, ${device.productId}, ${device.vendorId}) connection $e');
      return false;
    }
  }

  Future<bool> sendPrintCommand(
      {required PrinterDevice device, required List<int> bytes}) async {
    bool connected = await checkConnection(device);
    if(!connected) return false; 
    try {
      final sent =
          await printerManager.send(type: PrinterType.usb, bytes: bytes);
          print('send status : $sent');
      return sent;
    } catch (e) {
      debugPrintStack(maxFrames: 2);
      throw Exception('Failed to send command to printer. $e');
    }
  }
}
