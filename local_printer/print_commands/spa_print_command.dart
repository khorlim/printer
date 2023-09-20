import 'dart:typed_data';

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../data_models/car_receipt.dart';
import '../../data_models/spa_receipt.dart';
import '../../printer_utils/dialogs.dart';

Future<void> spaReceipt(BuildContext context, NetworkPrinter printer,
    SpaReceiptData printData) async {
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

Future<void> carReceipt(BuildContext context, NetworkPrinter printer,
    CarReceiptData printData) async {
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
  printer.text('Car Plate : ${printData.carPlate}',
      styles: PosStyles(align: PosAlign.left));
  printer.text('Car Model : ${printData.carModel}',
      styles: PosStyles(align: PosAlign.left));
  printer.text('Location : ${printData.location}',
      styles: PosStyles(align: PosAlign.left));
  printer.text('Cashier : ${printData.cashierName}',
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
  }
  printer.hr();

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
