import 'package:flutter_star_prnt/flutter_star_prnt.dart';

import '../../data_models/car_receipt.dart';
import '../../data_models/spa_receipt.dart';
import '../../printer_utils/utils.dart';

PrintCommands spaReceipt(
    {required bool format58mm, required SpaReceiptData printData}) {
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

  int imageWidth = format58mm ? (576 / 1.8).ceil() : (576 / 2.6).ceil();
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

PrintCommands carReceipt(
    {required bool format58mm, required CarReceiptData printData}) {
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

  String invNumberLabel =
      printData.invNo == null ? '' : "INV No       : ${printData.invNo}";
  String cashierLabel =
      printData.cashierName == null ? '' : 
                         "Cashier     : ${printData.cashierName}";
  String staffLabel =    "Name        : ${printData.staffName}";
  String mobileLabel =   "Mobile      : ${printData.mobile}";
  String carPlateLabel = "Car Plate   : ${printData.carPlate}";
  String carModelLabel = "Car Model   : ${printData.carModel}";
                         

  // int spaceBetween = length - cashierLine.length -1;
  String header = "\n${alignCenter(printData.shopName, length)}\n"
      "${alignCenter(printData.address, length)}\n";

  String title = '';

  if (printData.receiptID != null) {
    title += "${alignCenter("Ticket #${printData.receiptID}", size12Length)}\n";
  }

  title += "${alignCenter("INVOICE", size12Length)}\n";

  String info = '';

  if (invNumberLabel.isNotEmpty) {
    info += "$invNumberLabel\n";
  }

  info += 
  
      "Sales Date   : ${printData.salesDate}\n"
      "Issued Date  : ${printData.issuedDate}\n"
      ".....................................................\n"
      "$staffLabel\n"
      "$mobileLabel\n"
      "$carPlateLabel\n"
      "$carModelLabel\n"
      "Location    : ${printData.location}\n";

  if (cashierLabel.isNotEmpty) {
    info += "$cashierLabel\n";
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

  String footer = printData.footer == null ? '' : "${alignCenter(printData.footer!, length)}\n";

  // String footer = "${alignCenter("Thank you", length)}\n"
  //     "${alignCenter("Please Come Again", length)}\n"
  //     "${alignCenter("Remain This Receipt To Get", length)}\n"
  //     "${alignCenter("10\$ Discount for Next Visit", length)}\n";

  int imageWidth = format58mm ? (576 / 1.8).ceil() : (576 / 2.6).ceil();
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
