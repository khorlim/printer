import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/engine/receipt/model/sub_models/r_field.dart';
import 'package:tunaipro/engine/receipt/model/sub_models/r_item.dart';
import 'package:tunaipro/engine/receipt/model/sub_models/r_payment.dart';
import 'package:tunaipro/extra_utils/printer/src/print_commander/super_print_commander.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/text_column.dart';

import '../../../../core/core_extension/double_extension.dart';
import 'abstract_receipt.dart';

class GeneralReceipt extends AbstractReceipt {
  final ReceiptData receiptData;
  double? iconSize;
  GeneralReceipt({
    required super.printerType,
    required super.paperSize,
    required this.receiptData,
    this.iconSize,
  });

  @override
  SuperPrintCommander getPrintCommand({bool openDrawer = false}) {
    final imagePath = receiptData.icon;

    printCommand.addImage(imagePath, iconSize: iconSize);
    printCommand.addEmptyLine();

    if (receiptData.shopAddress.isNotEmpty) {
      addMultiLine(receiptData.shopAddress, linesAfter: 1);
    }

    if (receiptData.title.isNotEmpty) {
      printCommand.addTextLine(
        receiptData.title,
        fontSizeType: FontSizeType.big,
        alignment: PosAlign.center,
        bold: true,
        linesAfter: 2,
      );
    }

    printCommand.addTextLine('Name : ${receiptData.customerName}');

    if (receiptData.customerMobile != null) {
      printCommand.addTextLine('Mobile : ${receiptData.customerMobile!}');
    }

    addFieldLines(receiptData.field);

    if (receiptData.customerDetail != null) {
      if (receiptData.customerDetail!.hasCarModel) {
        printCommand
            .addTextLine('Car Model : ${receiptData.customerDetail!.carModel}');
      }
      if (receiptData.customerDetail!.hasCarPlate) {
        printCommand
            .addTextLine('Car Plate : ${receiptData.customerDetail!.carPlate}');
      }
      if (receiptData.customerDetail!.hasCredit) {
        printCommand.addTextLine(
            'Credit : ${receiptData.customerDetail!.credit.format()}');
      }
      if (receiptData.customerDetail!.hasPoint) {
        printCommand.addTextLine(
            'Point : ${receiptData.customerDetail!.point.format()}');
      }
      if (receiptData.customerDetail!.hasOutstanding) {
        printCommand.addTextLine(
            'Outstanding : ${receiptData.customerDetail!.outstanding.format()}');
      }
    }

    printCommand.addEmptyLine();

    addItemColumn(receiptData.items);

    addPayments(receiptData.payments);

    printCommand.addEmptyLine(line: 2);

    addMultiLine(receiptData.footer);

    if (openDrawer) {
      printCommand.openCashDrawer();
    }

    return printCommand;
  }

  void addMultiLine(List<String> multiLineString,
      {int linesAfter = 0, bool center = true}) {
    for (String text in multiLineString) {
      printCommand.addTextLine(text,
          alignment: center ? PosAlign.center : PosAlign.left);
    }
    if (linesAfter > 0) {
      printCommand.addEmptyLine(line: linesAfter);
    }
  }

  void addFieldLines(List<RField> fields, {int linesAfter = 0}) {
    for (var field in fields) {
      if (field.title == 'Timezone' || field.title == 'Issued Date') continue;
      printCommand.addTextLine('${field.title} : ${field.value}');
    }
    if (linesAfter > 0) {
      printCommand.addEmptyLine(line: linesAfter);
    }
  }

  void addItemColumn(List<RItem> items, {int linesAfter = 0}) {
    printCommand.addLine();
    printCommand.addTextRow([
      TextColumn(
        text: 'Item Price',
        ratio: 3,
      ),
      TextColumn(
        text: 'Discount',
        ratio: 3,
      ),
      TextColumn(
        text: 'Qty',
        ratio: 1,
      ),
      TextColumn(text: 'Total', ratio: 2, alignment: PosAlign.right),
    ]);
    printCommand.addLine();
    for (var item in items) {
      printCommand.addTextLine(item.description);
      if (item.extra != null) {
        for (var extra in item.extra!) {
          printCommand.addTextLine(extra.description);
        }
      }
      printCommand.addEmptyLine();
      printCommand.addTextRow([
        TextColumn(
          text: item.price,
          ratio: 3,
        ),
        TextColumn(
          text: item.discount.toStringAsFixed(2),
          ratio: 3,
        ),
        TextColumn(
          text: item.qty.toString(),
          ratio: 1,
        ),
        TextColumn(text: item.amount, ratio: 2, alignment: PosAlign.right),
      ]);
      printCommand.addLine();
    }
  }

  void addPayments(List<RPayment> payments) {
    for (var payment in payments) {
      printCommand.addTextRow([
        TextColumn(
          text: payment.text,
          ratio: 3,
          alignment: PosAlign.right,
          //bold: payment.bold,
        ),
        TextColumn(
          text: payment.amount,
          ratio: 1,
          alignment: PosAlign.right,
          // bold: payment.bold,
        )
      ]);
      if (payment.linebreak) {
        printCommand.addLine();
      }
    }
  }
}
