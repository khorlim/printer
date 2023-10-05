import 'dart:async';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:network_discovery/network_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:bluetooth_print/bluetooth_print.dart';
//import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'bluetooth_printer/blueprint.dart';
import 'bluetooth_printer/bluetooth_print.dart';
import 'data_models/car_receipt.dart';
import 'data_models/print_data.dart';
import 'data_models/spa_receipt.dart';
import 'data_models/spa_workslip.dart';
import 'local_printer/local_print.dart';
import 'printer_utils/dialogs.dart';
import 'printer_utils/utils.dart';
import 'star_printer/star_prnt.dart';

/* Packages 
  flutter_star_prnt: ^2.4.1
  esc_pos_printer: ^4.1.0
  esc_pos_utils: ^1.1.0
  cupertino_icons: ^1.0.2
  network_discovery: ^1.0.0
  shared_preferences: ^2.2.0
  bluetooth_print: ^4.3.0
*/

/* Prerequisite
Need to add this into your info.plist for star bluetooth printers
ios/Runner/Info.plist
<key>UISupportedExternalAccessoryProtocols</key>
  <array>
    <string>jp.star-m.starpro</string>
  </array>

<dict>  
	    <key>NSBluetoothAlwaysUsageDescription</key>  
	    <string>Need BLE permission</string>  
	    <key>NSBluetoothPeripheralUsageDescription</key>  
	    <string>Need BLE permission</string>  
	    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>  
	    <string>Need Location permission</string>  
	    <key>NSLocationAlwaysUsageDescription</key>  
	    <string>Need Location permission</string>  
	    <key>NSLocationWhenInUseUsageDescription</key>  
	    <string>Need Location permission</string>
*/

class PrintReceipt {
  List<PortInfo> foundStarPrinter = [];
  List<String> foundLanXPrinter = [];
  BluetoothDevice? foundBTPrinter;

  bool printerFound = false;

  String printerType = "";
  String printerPort = "";
  String printerModel = "";

  List<ScanResult>? scanResult = [];

  //   printData = PrintData(
  //     context: context,
  //     shopName: shopName,
  //     shopIcon: shopIcon,
  //     address: address,
  //     receiptID: receiptID,
  //     invNo: invNo,
  //     salesDate: salesDate,
  //     issuedDate: issuedDate,
  //     cashierName: cashierName,
  //     staffName: staffName,
  //     masseurName: masseurName,
  //     mobile: mobile,
  //     roomName: roomName,
  //     location: location,
  //     // subtotal: subtotal,
  //     // outstanding: outstanding,
  //     // rounding: rounding,
  //     // grandTotal: grandTotal,
  //     services: services,
  //     payments: payments,
  //   );

  Future<void> loadPrinterSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    printerType = prefs.getString('printerType') ?? '';
    printerPort = prefs.getString('printerPort') ?? '';
    printerModel = prefs.getString('printerModel') ?? '';
  }

  Future<void> savePrinterSettings(
      String pType, String pPort, String mName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('printerType', pType);
    await prefs.setString('printerPort', pPort);
    await prefs.setString('printerModel', mName);

    printerType = pType;
    printerPort = pPort;
    printerModel = mName;
  }

  Future<void> clearPrinterSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('printerType');
    await prefs.remove('printerPort');
    await prefs.remove('printerModel');
    printerFound = false;
  }

  Future<bool> findAnyPrinter(BuildContext context) async {
    showLoadingDialog(context, 'Finding printer...');
    await loadPrinterSettings();
    print(
        'stored printer type: ${printerType.isEmpty ? 'Empty' : printerType}');
    //if no printer type store in local then search for new printer
    if (printerType == '') {
      print('finding printer.....');
      await findStarPrinter();
      if (foundStarPrinter.isEmpty) {
        await findLanPrinterThroughPort();
      }

      if (foundStarPrinter.isEmpty && foundLanXPrinter.isEmpty) {
        await findConnectedBtPrinter();
      }

      print('stopped finding printer.....');
      print('found printer : $printerFound');
      hideLoadingDialog(context);
      if (!printerFound) {
        // showAlertDialog(
        //     context, 'No Printer Found', 'Unable to locate any printer');

        await performBluetoothScan(context);

        if (scanResult != null) {
          // ignore: use_build_context_synchronously
          await showDialog(
            context: context,
            builder: (BuildContext ctxt) {
              return AlertDialog(
                title: Text('Bluetooth Devices'),
                content: Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: scanResult!.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      final result = scanResult![index];
                      return ListTile(
                        title:
                            Text(result.device.localName ?? 'Unknown Device'),
                        subtitle: Text(result.device.remoteId.toString()),
                        onTap: () async {
                          printerFound = true;
                          await result.device.connect();
                          foundBTPrinter = result.device;
                          await savePrinterSettings('xbt', '', '');
                          Navigator.pop(ctxt);
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        }
      }
      return printerFound;
    } else {
      printerFound = true;
      hideLoadingDialog(context);
      return printerFound;
    }
  }

  Future<void> performBluetoothScan(BuildContext context) async {
    // search already connected devices, including devices
// connected to by other apps
    showLoadingDialog(context, 'Scanning bluetooth device...');
    // Start scanning
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    // Device not found? See "Common Problems" in the README
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      List<ScanResult> validResults = [];

      for (var result in results) {
        if (result.device.localName.isNotEmpty) {
          validResults.add(result);
        }
      }
      scanResult = validResults;
    });

    // Wait for the scanning period (4 seconds in this case)
    await Future.delayed(Duration(seconds: 4));

    // Stop scanning
    await FlutterBluePlus.stopScan();
    hideLoadingDialog(context);
    // Cancel the subscription
    subscription.cancel();
  }

  Future<void> findConnectedBtPrinter() async {
    List<BluetoothDevice> connectedDevices =
        await FlutterBluePlus.connectedSystemDevices;
    for (var device in connectedDevices) {
      print("connected device : ${device.localName}");
    }
    if (connectedDevices.length > 0) {
      foundBTPrinter = connectedDevices[0];
      await savePrinterSettings('xbt', '', '');
      printerFound = true;
      // printWithDevice(connectedDevices[0]);
    } else {
      foundBTPrinter = null;
    }
  }

  Future<void> startPrint(BuildContext context, PrintData printData) async {
    //showLoadingDialog(context);
    print(
        'Printing through printer : ${printerType.isEmpty ? 'Null' : printerType}');
    if (printerType == 'star') {
      StarPrinter starPrinter = StarPrinter(
          context: context,
          portName: printerPort,
          modelName: printerModel,
          searchAndStartPrint: () async {
            await clearPrinterSettings();
            await findAnyPrinter(context);
            if (printerFound) {
              startPrint(context, printData);
            }
          });
      try {
        starPrinter.startPrint(printData: printData);
      } catch (e) {
        print('failed to print with star printer: $e');
      }
    }
    // starPrinterPrint(context, printerPort, printerModel);

    if (printerType == 'xlan') {
      LocalPrint localPrint = LocalPrint(
          context: context,
          addr: printerPort,
          searchAndStartPrint: () async {
            await clearPrinterSettings();
            await findAnyPrinter(context);
            if (printerFound) {
              startPrint(context, printData);
            }
          });
        localPrint.print(printData: printData);
    }
    if (printerType == 'xbt') {
      try {
        if (foundBTPrinter == null) {
          await findConnectedBtPrinter();
        }
        if (foundBTPrinter == null) {
          print('no printer connection found');
          clearPrinterSettings();
          await findAnyPrinter(context);
          if (printerFound) {
            startPrint(context, printData);
          }
        } else {
          BluetoothPrint btPrint = BluetoothPrint(
              context: context,
              device: foundBTPrinter!,
              searchAndStartPrint: () async {
                await clearPrinterSettings();
                await findAnyPrinter(context);
                if (printerFound) {
                  startPrint(context, printData);
                }
              });

          switch (printData.runtimeType) {
            case SpaReceiptData:
              SpaReceiptData spaReceiptData = printData as SpaReceiptData;
              btPrint.spaReceiptPrint(spaReceiptData);
              break;
            case SpaWorkSlipData:
              SpaWorkSlipData spaWorkSlipData = printData as SpaWorkSlipData;
              btPrint.spaWorkSlipPrint(spaWorkSlipData);
              break;
            case CarReceiptData:
              CarReceiptData carReceiptData = printData as CarReceiptData;
              btPrint.carReceiptPrint(carReceiptData);
              break;
          }
        }
      } catch (e) {
        print('failed to print with bt printer: $e');
      }
    }
  }

  Future<void> findLanPrinterThroughPort() async {
    print('finding printer through port');
    const List<int> ports = [9100, 6001];
    final stream = NetworkDiscovery.discoverMultiplePorts('192.168.0', ports, timeout: Duration(seconds: 2));
    final completer = Completer<void>();
    int found = 0;
    stream.listen((
      NetworkAddress addr,
    ) {
    
      found++;
      foundLanXPrinter.add("${addr.ip}");
      print('Found device: ${addr.ip}:${addr.openPorts}');
    }).onDone(() async {
      print('Finish. Found $found device(s)');
      completer.complete();
    });

    // Wait for the completer to complete before proceeding
    try {
      await completer.future;
      if (foundLanXPrinter.isNotEmpty) {
        savePrinterSettings('xlan', '${foundLanXPrinter[0]}', '');

        printerFound = true;
      }
      // print('complete');
      // Now you can continue with your further code execution
    } catch (error) {
      print('An error occurred: $error');
    }
  }

  Future<void> findStarPrinter() async {
    try {
      List<PortInfo> starPrinters =
          await StarPrnt.portDiscovery(StarPortType.All);
      foundStarPrinter = starPrinters;

      if (foundStarPrinter.isNotEmpty) {
        await savePrinterSettings('star', '${foundStarPrinter[0].portName}',
            '${foundStarPrinter[0].modelName!}');
        printerFound = true;
      }
    } catch (e) {
      print(e);
    }
  }
}

void showPrinterSelectionDialog(
    BuildContext context,
    List<dynamic> xPrinters,
    List<dynamic> foundBtPrinters,
    List<dynamic> starPrinters,
    Function(dynamic) onSelectStarPrinter,
    Function(dynamic) onSelectXPrinter) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text('Select a Printer'),
        content: Column(
          children: [
            Text('Choose a printer to continue:'),
            SizedBox(height: 8),
            Column(
              children: xPrinters.map((printer) {
                return SizedBox(
                  width: 200,
                  child: CupertinoButton(
                    //  color: Colors.yellow,
                    onPressed: () {
                      onSelectXPrinter(printer);
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text(
                      printer,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
            Column(
              children: foundBtPrinters.map((printer) {
                return SizedBox(
                  width: 200,
                  child: CupertinoButton(
                    //  color: Colors.yellow,
                    onPressed: () {
                      onSelectXPrinter(printer);
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text(
                      printer,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
            Column(
              children: starPrinters.map((printer) {
                return SizedBox(
                  width: 200,
                  child: CupertinoButton(
                    //  color: Colors.yellow,
                    onPressed: () {
                      onSelectStarPrinter(printer);
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text(
                      printer.modelName.replaceAll(' ', ''),
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}
