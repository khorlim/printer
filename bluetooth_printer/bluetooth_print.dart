import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../data_models/car_receipt.dart';
import '../data_models/spa_receipt.dart';
import '../data_models/spa_workslip.dart';
import '../printer_utils/dialogs.dart';
import 'blueprint.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class BluetoothPrint {
  final BuildContext context;
  final BluetoothDevice device;
  final Function searchAndStartPrint;

  BluetoothPrint(
      {required this.context,
      required this.device,
      required this.searchAndStartPrint});

  Future<void> spaReceiptPrint(SpaReceiptData printData) async {
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

    try {
      await printer.printData(device);
    } catch (e) {
      searchAndStartPrint();
    }
  }

  Future<void> carReceiptPrint(CarReceiptData printData) async {
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
    if (printData.receiptID != null) {
      printer.add(gen.text('Ticket #${printData.receiptID}',
          styles: PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )));
    }
    printer.add(gen.text('INVOICE',
        linesAfter: 2,
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    if (printData.invNo != null) {
      printer.add(gen.text('INV No      : ${printData.invNo}',
          styles: PosStyles(align: PosAlign.left)));
    }
    printer.add(gen.text('Sales Date  : ${printData.salesDate}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Issued Date : ${printData.issuedDate}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.hr());
    printer.add(gen.text('Name      : ${printData.staffName}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Mobile    : ${printData.mobile}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Car Plate : ${printData.carPlate}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Car Model : ${printData.carModel}',
        styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.text('Location  : ${printData.location}',
        styles: PosStyles(align: PosAlign.left)));
    if (printData.cashierName != null) {
      printer.add(gen.text('Cashier   : ${printData.cashierName}',
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
    if (printData.footer != null) {
      printer.add(gen.text(printData.footer!,
          styles: PosStyles(align: PosAlign.center)));
    }
    printer.add(gen.feed(2));
    printer.add(gen.cut());

    try {
      await printer.printData(device);
    } catch (e) {
      searchAndStartPrint();
    }
  }

  Future<void> spaWorkSlipPrint(SpaWorkSlipData printData) async {
    // Get the negotiated MTU value
    final negotiatedMTU = await device.mtu.first;

    //print('Negotiated MTU: $negotiatedMTU');

    final gen = Generator(PaperSize.mm80, await CapabilityProfile.load());
    final printer = BluePrint(chunkLen: 182);

    printer.add(gen.text('** REPRINT **',
        linesAfter: 1,
        styles: PosStyles(
          bold: true,
          align: PosAlign.center,
        )));
    printer.add(gen.text('JOB TICKET',
        linesAfter: 1,
        styles: PosStyles(
          align: PosAlign.center,
        )));

    printer.add(gen.row([
      PosColumn(
          text: 'Name   : ${printData.memberName}',
          width: 7,
          styles: PosStyles(align: PosAlign.left)),
      PosColumn(
          text: 'Masseur: ${printData.staffName}',
          width: 5,
          styles: PosStyles(align: PosAlign.left)),
    ]));
    printer.add(gen.row([
      PosColumn(
          text: 'Mobile : ${printData.memberMobile}',
          width: 7,
          styles: PosStyles(align: PosAlign.left)),
      PosColumn(
          text: 'Room : ${printData.roomName}',
          width: 5,
          styles: PosStyles(align: PosAlign.left)),
    ]));
    printer.add(gen.feed(1));

    printer.add(gen.text('Issued Date : ${printData.issuedDate}',
        linesAfter: 1, styles: PosStyles(align: PosAlign.left)));
    printer.add(gen.hr());
    printer.add(gen.feed(1));

    for (String serviceText in printData.services) {
      printer
          .add(gen.text(serviceText, styles: PosStyles(align: PosAlign.left)));
    }
    printer.add(gen.hr());
    printer.add(gen.feed(1));
    printer.add(gen.text(printData.timeString,
        styles: PosStyles(bold: true, align: PosAlign.center)));
    printer.add(gen.feed(2));
    printer.add(gen.cut());

    try {
      await printer.printData(device);
    } catch (e) {
      searchAndStartPrint();
    }
  }
}
