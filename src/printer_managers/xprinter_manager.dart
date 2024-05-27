// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/cupertino.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:tunaipro/extra_utils/printer/src/utils/port_scanner.dart';
// import 'package:thermal_printer/thermal_printer.dart';


// class XPrinterManager {
//   static final XPrinterManager _instance = XPrinterManager._internal();

//   factory XPrinterManager() {
//     return _instance;
//   }

//   XPrinterManager._internal();


//   final int _port = 9100;
//   final Duration _timeout = const Duration(seconds: 3);

//   Future<void> setupXPrinter({String currentPrinterIp = '192.168.123.100', required String newPrinterIP}) async {
//     // final stream = PortScanner.discover(printerSubnet, _port, timeout: _timeout);

//     final Completer<PrinterDevice?> completer = Completer();

//     final xprinter = await PortScanner.discoverFromAddress(currentPrinterIp, _port, timeout: _timeout);
//     if(xprinter.openPorts.isNotEmpty && xprinter.openPorts.contains(9100)) {
//       print('Found XPrinter at $currentPrinterIp : $_port');
//       final ipBytes = constructChangeIpCommand(newPrinterIP);
//       try {
//         sendRawBytes(currentPrinterIp, _port, ipBytes);
//       }catch(e) {
//         print('Failed to change xprinter IP address : $e');
//         throw XPrinterFailedToChangeIpException();
//       }
//     } else {
//       throw XPrinterNotFoundException();
//     }
   
       
//   }


//   Future<void> sendRawBytes(String printerIp, int port, List<int> bytes) async {
//   Socket socket;
//   try {
//     socket = await Socket.connect(printerIp, port);
//     print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
    
//     // Send the raw bytes
//     socket.add(Uint8List.fromList(bytes));
    
//     await socket.flush();
//     socket.destroy();
//     print('Command sent successfully!');
//   } catch (e) {
//     print('Failed to connect or send data: $e');
//   }
// }

// List<int> constructChangeIpCommand(String newIp) {
//   final ipParts = newIp.split('.').map(int.parse).toList();
  
//   // Command to change IP address based on the provided example
//   return [
//     0x1f, 0x1b, 0x1f, 0x91, 0x00, 0x49, 0x50,
//     ipParts[0], ipParts[1], ipParts[2], ipParts[3]
//   ];
// }

 

 
// }

// class XPrinterNotFoundException implements Exception{

// }

// class XPrinterFailedToChangeIpException implements Exception{

// }

