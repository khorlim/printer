import 'dart:async';
import 'package:esc_pos_printer/esc_pos_printer.dart' as lanX;
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

import '../blueprint.dart';
import 'printer_utils/dialogs.dart';
import 'printer_utils/spa_print_data.dart';
import 'printer_utils/utils.dart';

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

  late PrintData printData;

  bool printerFound = false;
  bool isFindingPrinter = false;

  String printerType = "";
  String printerPort = "";
  String printerModel = "";

  DateTime currentTime = DateTime.now();

  List<ScanResult>? scanResult = [];

  void createPrintData({
    required BuildContext context,
    required String shopName,
    required String shopIcon,
    required String address,
    required String receiptID,
    required String invNo,
    required String salesDate,
    required String issuedDate,
    required String cashierName,
    required String staffName,
    String? masseurName,
    required String mobile,
    required String roomName,
    required String location,
    // required String subtotal,
    // required String outstanding,
    // required String rounding,
    // required String grandTotal,
    required List<Map<String, String>> services,
    required List<Map<String, dynamic>> payments,
  }) {
    printData = PrintData(
      context: context,
      shopName: shopName,
      shopIcon: shopIcon,
      address: address,
      receiptID: receiptID,
      invNo: invNo,
      salesDate: salesDate,
      issuedDate: issuedDate,
      cashierName: cashierName,
      staffName: staffName,
      masseurName: masseurName,
      mobile: mobile,
      roomName: roomName,
      location: location,
      // subtotal: subtotal,
      // outstanding: outstanding,
      // rounding: rounding,
      // grandTotal: grandTotal,
      services: services,
      payments: payments,
    );
  }

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
    print('printer type: $printerType');
    //if no printer type store in local then search for new printer
    if (printerType == '') {
      print('finding printer.....');
      isFindingPrinter = true;
      await findStarPrinter();
      if (foundStarPrinter.isEmpty) {
        await findLanPrinterThroughPort();
      }

      if (foundStarPrinter.isEmpty && foundLanXPrinter.isEmpty) {
        await findConnectedBtPrinter();
      }

      isFindingPrinter = false;
      print('stopped finding printer.....');
      print('found printer : $printerFound');
      hideLoadingDialog(context);
      if (!printerFound) {
        // showAlertDialog(
        //     context, 'No Printer Found', 'Unable to locate any printer');

        await performBluetoothScan(context);

        if (scanResult != null) {
          // ignore: use_build_context_synchronously
          showDialog(
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
                          Navigator.pop(ctxt); // Close the dialog
                          await result.device.connect();
                          savePrinterSettings('xbt', '', '');
                          printWithBTDevice(result.device,
                              context); // Call the printing function
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
      printerFound = true;
      // printWithDevice(connectedDevices[0]);
    } else {
      foundBTPrinter = null;
    }
  }

  Future<void> startPrint(BuildContext context) async {
    print('saved printer type : $printerType');
    //showLoadingDialog(context);

    if (printerType == 'star') {
      starPrinterPrint(context, printerPort, printerModel);
    }
    if (printerType == 'xlan') {
      xprinterPrint(context, printerPort);
    }
    if (printerType == 'xbt') {
      await findConnectedBtPrinter();
      if (foundBTPrinter == null) {
        print('no printer connection found');
        clearPrinterSettings();
        await findAnyPrinter(context);
        if (printerFound) {
          startPrint(context);
        }
      } else {
        printWithBTDevice(foundBTPrinter!, context);
      }
    }
    // if (foundStarPrinter.isNotEmpty) {
    //   print('printing through star printer');
    //   starPrinterPrint(context, foundStarPrinter[0]);
    // }
    // if (foundLanXPrinter.isNotEmpty) {
    //   print('printing through lan x printer');

    //   xprinterPrint(context, foundLanXPrinter[0]);
    // }
    // if (foundBTPrinter != null) {
    //   print('printing through bluetooth x printer');
    //   printWithBTDevice(foundBTPrinter!);
    // }

    //await loadPrinterSettings();
    //  findBluetoothPrinter();
    // if (printerType == '') {
    //   try {
    //     await findLanPrinterThroughPort();
    //     await findStarPrinter();
    //     if (foundStarPrinter.length > 0 || foundLanXPrinter.length > 0) {
    //       hideLoadingDialog(context);
    //       // ignore: use_build_context_synchronously
    //       showPrinterSelectionDialog(
    //           context, foundLanXPrinter, foundBtPrinters, foundStarPrinter,
    //           (selectedPrinter) async {
    //         if (selectedPrinter.portName?.isNotEmpty != null) {
    //           //Print through star printer
    //           try {
    //             PrintCommands commands = starReceiptCommand();
    //             PrinterResponseStatus responseStatus =
    //                 await StarPrnt.sendCommands(
    //                     portName: selectedPrinter.portName!,
    //                     emulation: emulationFor(selectedPrinter.modelName!),
    //                     printCommands: commands);
    //             if (responseStatus.isSuccess) {
    //               showAlertDialog(context, 'Success', 'Print successful');
    //             } else {
    //               showAlertDialog(context, 'Failed',
    //                   'Print failed with status: ${responseStatus.toString()}');
    //             }
    //           } catch (e) {
    //             hideLoadingDialog(context);
    //             showAlertDialog(context, 'Error', "$e");
    //           }
    //         }
    //       }, (xlanprinter) {
    //         //Print through local x printer
    //         xprinterPrint(xlanprinter);
    //       });
    //     } else {
    //       hideLoadingDialog(context);
    //       showAlertDialog(context, 'No printer found', '');
    //       return;
    //     }
    //   } catch (e) {
    //     hideLoadingDialog(context);
    //     showAlertDialog(context, 'Error', '$e');
    //   }
    // } else {
    //   //Directly print if printer setting found
    // }
  }

  Future<void> starPrinterPrint(
      BuildContext context, String portName, String modelName) async {
    bool format58mm = modelName.contains('POP10');
    try {
      showLoadingDialog(context, 'Printing');
      PrintCommands commands = starReceiptCommand(format58mm: format58mm);
      PrinterResponseStatus responseStatus = await StarPrnt.sendCommands(
          portName: portName,
          emulation: emulationFor(modelName),
          printCommands: commands);
      if (responseStatus.isSuccess) {
        hideLoadingDialog(context);
        showAlertDialog(context, 'Success', 'Print successful');
      } else {
        hideLoadingDialog(context);
        showAlertDialog(context, 'Failed',
            'Print failed with status: ${responseStatus.toString()}');
      }
    } catch (e) {
      hideLoadingDialog(context);

      // showAlertDialog(context, 'Error', "$e");
      await clearPrinterSettings();
      await findAnyPrinter(context);
      if (printerFound) {
        startPrint(context);
      }
    }
  }

  Future<void> findLanPrinterThroughPort() async {
    const List<int> ports = [9100];
    final stream = NetworkDiscovery.discoverMultiplePorts('192.168.0', ports);
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
    List<PortInfo> starLanList = await StarPrnt.portDiscovery(StarPortType.All);
    foundStarPrinter = starLanList;
    // for (var printer in starLanList) {
    //   print(emulationFor(printer.modelName!));
    //   print(printer.modelName);
    //   bool bigFormat = printer.modelName!.contains('POP10');
    //   print(bigFormat);
    // }
    if (foundStarPrinter.isNotEmpty) {
      await savePrinterSettings('star', '${foundStarPrinter[0].portName}',
          '${foundStarPrinter[0].modelName!}');
      printerFound = true;
    }
  }

  void xprinterPrint(BuildContext context, String addr) async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = lanX.NetworkPrinter(paper, profile);

    final lanX.PosPrintResult res = await printer.connect(addr, port: 9100);

    if (res == lanX.PosPrintResult.success) {
      await xprinterReceipt(context, printer);
      printer.disconnect();
      showAlertDialog(context, 'Success', 'Print successful');
    } else {
      // showAlertDialog(context, 'Failed', 'Failed to print');
      await clearPrinterSettings();
      await findAnyPrinter(context);
      if (printerFound) {
        startPrint(context);
      }
    }
  }

  Future<void> xprinterReceipt(
      BuildContext context, lanX.NetworkPrinter printer) async {
    // String formattedCurrentTime =
    //     DateFormat('d/M/yyyy H:mm:ss').format(currentTime);
    // String shopName = "McDonald Kfc BurgerKINg";
    // String shopIcon =
    //     "https://img.tunai.io/image/s3-9ff0ec03-88e8-4562-9f33-530d8425cbb3.jpeg";
    // String address =
    //     "501, Block A4, Leisure Commerce Square, Thailand, Singapore, Vietnam, Malaysia, Mars, Black hole";
    // String invNo = "123456789";
    // String salesDate = formattedCurrentTime;
    // String issuedDate = "8/8/2023 12:12:12";
    // String cashierName = "Khor Lim Han";
    // String staffName = "Dayon";
    // String masseurName = "Yati";
    // String mobile = "60102812876";
    // String roomName = "Biggest Room";
    // String location = "Kuala lumpur";
    // String subtotal = "10000.00";
    // String outstanding = "500.00";
    // String rounding = "00.00";
    // String grandTotal = "00000.00";
    // List<Map<String, String>> services = [
    //   {
    //     "name": "Hair Removal",
    //     "price": "1100.00",
    //     "discount": "100.00",
    //     "quantity": "1",
    //     "amount": "1000.00"
    //   },
    //   {
    //     "name": "Spa Treatment Testing Long Very Long Name",
    //     "price": "500.00",
    //     "discount": "50.00",
    //     "quantity": "1",
    //     "amount": "450.00"
    //   },
    //   {
    //     "name": "Facial Treatment",
    //     "price": "150.00",
    //     "discount": "100.00",
    //     "quantity": "1",
    //     "amount": "50.00"
    //   }
    // ];
    // List<Map<String, String>> payments = [
    //   {
    //     "paymentMethod": "Touch N Go",
    //     "amount": "0000.00",
    //   },
    //   {
    //     "paymentMethod": "Credit Card",
    //     "amount": "0000.00",
    //   },
    //   {
    //     "paymentMethod": "Cash",
    //     "amount": "0000.00",
    //   },
    // ];
    showLoadingDialog(context, 'Printing');
    img.Image? image;
    final response = await http.get(Uri.parse(printData.shopIcon));

    if (response.statusCode == 200) {
      final imageData = response.bodyBytes;
      image = img.decodeImage(Uint8List.fromList(imageData));
    } else {
      print('failed to load image');
    }
    printer.image(image!);
    printer.text('${printData.shopName}',
        linesAfter: 1,
        styles: PosStyles(
          align: PosAlign.center,
        ));
    printer.text('${printData.address}',
        linesAfter: 1,
        styles: PosStyles(
          align: PosAlign.center,
        ));
    printer.text('Ticket #${printData.receiptID}\nINVOICE',
        linesAfter: 2,
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    printer.text('INV No : ${printData.invNo}',
        styles: PosStyles(align: PosAlign.left));
    printer.text('Sales Date : ${printData.salesDate}',
        styles: PosStyles(align: PosAlign.left));
    printer.text('Issued Date : ${printData.issuedDate}',
        styles: PosStyles(align: PosAlign.left));
    printer.hr();

    printer.text('Name : ${printData.staffName}',
        styles: PosStyles(align: PosAlign.left));

    printer.text('Mobile : ${printData.mobile}',
        styles: PosStyles(align: PosAlign.left));
    printer.text('Location : ${printData.location}',
        styles: PosStyles(align: PosAlign.left));
    printer.text('Cashier : ${printData.cashierName}',
        styles: PosStyles(align: PosAlign.left));
    if (printData.masseurName != null)
      printer.text('Massuer : ${printData.masseurName}',
          styles: PosStyles(align: PosAlign.left));
    printer.feed(1);
    printer.hr();
    String descriptionHeader = "Description      ";
    String priceHeader = "Price";
    String discountHeader = "    Discount";
    String quantityHeader = "   Qty";
    String amountHeader = "  Amount";
    String serviceHeaders =
        "$descriptionHeader$priceHeader$discountHeader$quantityHeader$amountHeader";
    printer.text(serviceHeaders);
    // printer.row([
    //   PosColumn(
    //       text: 'Description',
    //       width: 4,
    //       styles: PosStyles(align: PosAlign.left,)),
    //   PosColumn(
    //       text: 'Price', width: 2, styles: PosStyles(align: PosAlign.right)),
    //   PosColumn(
    //       text: 'Discount', width: 3, styles: PosStyles(align: PosAlign.right)),
    //   PosColumn(
    //       text: 'Qty', width: 1, styles: PosStyles(align: PosAlign.right)),
    //   PosColumn(
    //       text: 'Amount', width: 2, styles: PosStyles(align: PosAlign.right)),
    // ]);
    printer.hr();

    for (var item in printData.services) {
      String serviceName = item["name"]!;
      String price = item["price"]!;
      String discount = item["discount"]!;
      String quantity = item["quantity"]!;
      String amount = item["amount"]!;
      String servicesLabel =
          "${price.padLeft(descriptionHeader.length + priceHeader.length)}${discount.padLeft(discountHeader.length)}${quantity.padLeft(quantityHeader.length)}${amount.padLeft(amountHeader.length)}";
      printer.text(serviceName,
          containsChinese: true,
          linesAfter: 1,
          styles: PosStyles(
            align: PosAlign.left,
          ));

      printer.text(servicesLabel, linesAfter: 1, containsChinese: true);
      // printer.row([
      //   PosColumn(
      //       text: price, width: 6, styles: PosStyles(align: PosAlign.right)),
      //   PosColumn(
      //       text: discount, width: 2, styles: PosStyles(align: PosAlign.right)),
      //   PosColumn(
      //       text: quantity, width: 2, styles: PosStyles(align: PosAlign.right)),
      //   PosColumn(
      //       text: amount, width: 2, styles: PosStyles(align: PosAlign.right)),
      // ]);
      // printer.text(
      //   "",
      // );
    }
    printer.hr();

    // printer.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Subtotal', width: 3, styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.subtotal,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]);

    // printer.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Outstanding',
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.outstanding,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]);
    // printer.hr();
    // printer.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Rounding', width: 3, styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.rounding,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]);
    // printer.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Grand Total',
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.grandTotal,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]);

    // printer.hr(linesAfter: 1);

    for (int i = 0; i < printData.payments.length; i++) {
      String paymentName = printData.payments[i]['paymentMethod']!;
      String amount = printData.payments[i]['amount']!;
      bool bold = printData.payments[i]['bold'] ?? false;
      bool linebreak = printData.payments[i]['linebreak'] ?? false;

      bool isLastRow = i == printData.payments.length - 1;

      if (isLastRow) {
        printer.row([
          PosColumn(text: '', width: 6),
          PosColumn(
              text: paymentName,
              width: 3,
              styles: PosStyles(align: PosAlign.left, bold: bold)),
          PosColumn(
              text: amount, width: 3, styles: PosStyles(align: PosAlign.right)),
        ]);
        printer.hr(linesAfter: 2);
      } else {
        printer.row([
          PosColumn(text: '', width: 6),
          PosColumn(
              text: paymentName,
              width: 3,
              styles: PosStyles(align: PosAlign.left, bold: bold)),
          PosColumn(
              text: amount, width: 3, styles: PosStyles(align: PosAlign.right)),
        ]);
        if (linebreak) {
          printer.hr();
        }
      }
    }

    printer.text(
        "Thank you\nPlease come Again\nRemain This Receipt To Get\n10\$ Discount for Next Visit",
        styles: PosStyles(align: PosAlign.center));
    printer.feed(2);
    printer.cut();
    hideLoadingDialog(context);
  }

  void printWithBTDevice(BluetoothDevice device, BuildContext context) async {
    showLoadingDialog(context, 'Printing');
    // Get the negotiated MTU value
    final negotiatedMTU = await device.mtu.first;

    //print('Negotiated MTU: $negotiatedMTU');

    final gen = Generator(PaperSize.mm80, await CapabilityProfile.load());
    final printer = BluePrint(chunkLen: 182);

    img.Image? image;
    final response = await http.get(Uri.parse(printData.shopIcon));

    if (response.statusCode == 200) {
      image = img.decodeImage(response.bodyBytes);
    } else {
      hideLoadingDialog(context);
      print('Failed to load image');
    }
    printer.add(gen.image(image!));

    printer.add(gen.feed(1));

    printer.add(gen.text('${printData.shopName}',
        linesAfter: 1,
        styles: PosStyles(
          align: PosAlign.center,
        )));
    printer.add(gen.text('${printData.address}',
        linesAfter: 1,
        styles: PosStyles(
          align: PosAlign.center,
        )));
    printer.add(gen.text('Ticket #${printData.receiptID}\nINVOICE',
        linesAfter: 2,
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    printer.add(gen.text('INV No : ${printData.invNo}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Sales Date : ${printData.salesDate}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Issued Date : ${printData.issuedDate}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.hr());
    printer.add(gen.text('Name : ${printData.staffName}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Mobile : ${printData.mobile}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Location : ${printData.location}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Cashier : ${printData.cashierName}',
        styles: PosStyles(align: PosAlign.left)));
    if (printData.masseurName != null) {
      printer.add(gen.text('Massuer : ${printData.masseurName}',
          styles: PosStyles(align: PosAlign.left)));
    }
    printer.add(gen.feed(1));
    printer.add(gen.hr());

    String descriptionHeader = "Description      ";
    String priceHeader = "Price";
    String discountHeader = "    Discount";
    String quantityHeader = "   Qty";
    String amountHeader = "  Amount";
    String serviceHeaders =
        "$descriptionHeader$priceHeader$discountHeader$quantityHeader$amountHeader";
    printer.add(gen.text(serviceHeaders));
    printer.add(gen.hr());
    for (var item in printData.services) {
      String serviceName = item["name"]!;
      String price = item["price"]!;
      String discount = item["discount"]!;
      String quantity = item["quantity"]!;
      String amount = item["amount"]!;
      String servicesLabel =
          "${price.padLeft(descriptionHeader.length + priceHeader.length)}${discount.padLeft(discountHeader.length)}${quantity.padLeft(quantityHeader.length)}${amount.padLeft(amountHeader.length)}";
      printer.add(gen.text(serviceName,
          containsChinese: true,
          linesAfter: 1,
          styles: PosStyles(align: PosAlign.left)));

      printer.add(gen.text(servicesLabel, linesAfter: 1));
    }
    printer.add(gen.hr());

    // printer.add(gen.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Subtotal', width: 3, styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.subtotal,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]));
    // printer.add(gen.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Outstanding',
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.outstanding,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]));
    // printer.add(gen.hr());
    // printer.add(gen.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Rounding', width: 3, styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.rounding,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]));
    // printer.add(gen.row([
    //   PosColumn(text: '', width: 6),
    //   PosColumn(
    //       text: 'Grand Total',
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.left)),
    //   PosColumn(
    //       text: printData.grandTotal,
    //       width: 3,
    //       styles: PosStyles(align: PosAlign.right)),
    // ]));
    // printer.add(gen.hr(linesAfter: 1));

    for (int i = 0; i < printData.payments.length; i++) {
      String paymentName = printData.payments[i]['paymentMethod']!;
      String amount = printData.payments[i]['amount']!;
      bool bold = printData.payments[i]['bold'] ?? false;
      bool linebreak = printData.payments[i]['linebreak'] ?? false;

      bool isLastRow = i == printData.payments.length - 1;

      if (isLastRow) {
        printer.add(gen.row([
          PosColumn(text: '', width: 6),
          PosColumn(
              text: paymentName,
              width: 3,
              styles: PosStyles(align: PosAlign.left, bold: bold)),
          PosColumn(
              text: amount, width: 3, styles: PosStyles(align: PosAlign.right)),
        ]));
        printer.add(gen.hr(linesAfter: 2));
      } else {
        printer.add(gen.row([
          PosColumn(text: '', width: 6),
          PosColumn(
              text: paymentName,
              width: 3,
              styles: PosStyles(align: PosAlign.left, bold: bold)),
          PosColumn(
              text: amount, width: 3, styles: PosStyles(align: PosAlign.right)),
        ]));
        if (linebreak) {
          printer.add(gen.hr());
        }
      }
    }
    printer.add(gen.text(
        "Thank you\nPlease come Again\nRemain This Receipt To Get\n10\$ Discount for Next Visit",
        styles: PosStyles(align: PosAlign.center)));
    printer.add(gen.feed(2));
    printer.add(gen.cut());

    await printer.printData(device);
    hideLoadingDialog(context);
  }

  PrintCommands starReceiptCommand({required bool format58mm}) {
    print('58mm? : $format58mm');
    // String shopName = "McDonald Kfc BurgerKINg";
    // String shopIcon =
    //     "https://img.tunai.io/image/s3-9ff0ec03-88e8-4562-9f33-530d8425cbb3.jpeg";
    // String address =
    //     "501, Block A4, Leisure Commerce Square, Thailand, Singapore, Vietnam, Malaysia, Mars, Black hole";
    // String invNo = "123456789";
    // String salesDate = formattedCurrentTime;
    // String issuedDate = "8/8/2023 12:12:12";
    // String cashierName = "Khor Lim Han";
    // String staffName = "Dayon";
    // String masseurName = "Yati";
    // String mobile = "60102812876";
    // String roomName = "Biggest Room";
    // String location = "Kuala lumpur";
    // String subtotal = "10000.00";
    // String outstanding = "500.00";
    // String rounding = "00.00";
    // String grandTotal = "00000.00";
    // List<Map<String, String>> services = [
    //   {
    //     "name": "Hair Removal",
    //     "price": "1100.00",
    //     "discount": "100.00",
    //     "quantity": "1",
    //     "amount": "1000.00"
    //   },
    //   {
    //     "name": "Spa Treatment Testing Long Very Long Name",
    //     "price": "500.00",
    //     "discount": "50.00",
    //     "quantity": "1",
    //     "amount": "450.00"
    //   },
    //   {
    //     "name": "Facial Treatment",
    //     "price": "150.00",
    //     "discount": "100.00",
    //     "quantity": "1",
    //     "amount": "50.00"
    //   }
    // ];
    // List<Map<String, String>> payments = [
    //   {
    //     "paymentMethod": "Touch N Go",
    //     "amount": "0000.00",
    //   },
    //   {
    //     "paymentMethod": "Credit Card",
    //     "amount": "0000.00",
    //   },
    //   {
    //     "paymentMethod": "Cash",
    //     "amount": "0000.00",
    //   },
    // ];

    PrintCommands commands = PrintCommands();

    String receiptLength =
        ".....................................................";
    String fontSize12Length = "111111111111111111111111111111111111111\n";
    int size12Length = fontSize12Length.length;
    int length = receiptLength.length;

    String invNumberLabel = "INV No       : ${printData.invNo}";
    String cashierLabel = "Cashier: ${printData.cashierName}";
    String staffLabel = "Name     : ${printData.staffName}";
    String masseurLabel = "Massuer: ${printData.masseurName}";
    String mobileLabel = "Mobile   : ${printData.mobile}";
    String roomLabel = "Room: ${printData.roomName}";

    // int spaceBetween = length - cashierLine.length -1;
    String header = "\n${alignCenter(printData.shopName, length)}\n"
        "${alignCenter(printData.address, length)}\n";

    String title =
        "${alignCenter("Ticket #${printData.receiptID}", size12Length)}\n"
        "${alignCenter("INVOICE", size12Length)}\n";

    String info = "$invNumberLabel\n"
        "Sales Date   : ${printData.salesDate}\n"
        "Issued Date  : ${printData.issuedDate}\n"
        ".....................................................\n"
        "${staffLabel}\n";

    if (printData.roomName.isNotEmpty) {
      info += "${mobileLabel.padRight(length - roomLabel.length)}$roomLabel\n";
    } else {
      info += "$mobileLabel\n";
    }

    info += "Location : ${printData.location}\n" "$cashierLabel\n";
    if (printData.masseurName != null) {
      info += "$masseurLabel\n";
    }

    String separateLine =
        "-----------------------------------------------------\n";
    String descriptionHeader = "Description         ";
    String priceHeader = "Price";
    String discountHeader = "    Discount";
    String quantityHeader = "   Qty";
    String amountHeader = "    Amount";

    String service = "$separateLine"
        "$descriptionHeader$priceHeader$discountHeader$quantityHeader$amountHeader\n"
        "$separateLine";
    //  "${serviceName.padRight(descriptionHeader.length)}${price}\n\n";
    // "${serviceName.padRight(descriptionHeader.length)}${price.padRight(priceHeader.length)}${discount.padRight(discountHeader.length)}${quantity.padRight(quantityHeader.length)}${amount.padLeft(amountHeader.length)}\n\n";

    for (var item in printData.services) {
      String serviceName = item["name"]!;
      String price = item["price"]!;
      String discount = item["discount"]!;
      String quantity = item["quantity"]!;
      String amount = item["amount"]!;

      service += "${serviceName}\n\n"
          "${price.padLeft(descriptionHeader.length + priceHeader.length)}${discount.padLeft(discountHeader.length)}${quantity.padLeft(quantityHeader.length)}${amount.padLeft(amountHeader.length)}\n\n";
    }

    String total = "-----------------------------------------------------\n";
    // "${space((length / 2).ceil())}${"Subtotal".padRight((length / 2).truncate() - printData.subtotal.length)}${printData.subtotal}\n"
    // "${space((length / 2).ceil())}${"outstanding".padRight((length / 2).truncate() - printData.outstanding.length)}${printData.outstanding}\n"
    // "${space((length / 2).ceil())}${dash((length / 2).truncate())}\n"
    // "${space((length / 2).ceil())}${"Rounding".padRight((length / 2).truncate() - printData.rounding.length)}${printData.rounding}\n"
    // "${space((length / 2).ceil())}${"Grand Total".padRight((length / 2).truncate() - printData.grandTotal.length)}${printData.grandTotal}\n"
    // "${space((length / 2).ceil())}${dash((length / 2).truncate())}\n";

    String pay = "";

    if (printData.payments.isNotEmpty) {
      for (int i = 0; i < printData.payments.length; i++) {
        String paymentName = printData.payments[i]['paymentMethod']!;
        String amount = printData.payments[i]['amount']!;
        bool bold = printData.payments[i]['bold'] ?? false;
        bool linebreak = printData.payments[i]['linebreak'] ?? false;
        String methodLabel =
            "${paymentName.padRight((length / 2).truncate() - amount.length)}$amount";
        pay += "${methodLabel.padLeft(length)}\n";
        if (linebreak) {
          pay +=
              "${space((length / 2).ceil())}${dash((length / 2).truncate())}\n";
        }
        // Add dashed line only for the last payment
        if (i == printData.payments.length - 1) {
          pay +=
              "${space((length / 2).ceil())}${dash((length / 2).truncate())}\n"; // Dashed line
        }
      }
    } else {
      pay += " ";
    }

    String footer = "${alignCenter("Thank you", length)}\n"
        "${alignCenter("Please Come Again", length)}\n"
        "${alignCenter("Remain This Receipt To Get", length)}\n"
        "${alignCenter("10\$ Discount for Next Visit", length)}\n";
    
    int imageWidth = format58mm ? (576 / 1.8).ceil() : (576/2.6).ceil();
    commands.appendBitmap(
        path: printData.shopIcon,
        width: imageWidth,
        diffusion: false,
        bothScale: false,
        absolutePosition: ((576 - imageWidth) / 2).toInt()
       //  alignment: StarAlignmentPosition.Center,
        );

    commands.appendBitmapText(
      text: header,
      fontSize: 9,
    );
    commands.appendBitmapText(text: title, fontSize: 12);
    commands.appendBitmapText(text: info, fontSize: 9);
    commands.appendBitmapText(text: service, fontSize: 9);
    commands.appendBitmapText(text: total, fontSize: 9);
    commands.appendBitmapText(text: pay, fontSize: 9);
    commands.appendBitmapText(text: footer, fontSize: 9);
    commands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);

    return commands;
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
