import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/engine/receipt/model/sub_models/r_field.dart';
import 'package:tunaipro/engine/receipt/model/sub_models/r_item.dart';
import 'package:tunaipro/engine/receipt/model/sub_models/r_payment.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/print_command_adapter.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/text_column.dart';

class GeneralReceipt {
  final PType printerType;
  final ReceiptData receiptData;

  late final PrintCommandAdapter printCommand =
      PrintCommandAdapter(printerType: printerType);

  GeneralReceipt({required this.printerType, required this.receiptData});

  Future<PrintCommandAdapter> getReceipt() async {
    final imagePath = receiptData.icon;

    await printCommand.initialize(imagePath: imagePath);

    printCommand.addImage(imagePath);
    printCommand.addEmptyLine();
    addMultiLine(receiptData.shopAddress, linesAfter: 1);

    printCommand.addTextLine(receiptData.title,
        fontSizeType: FontSizeType.big,
        alignment: PosAlign.center,
        bold: true,
        linesAfter: 2);

    addFieldLines(receiptData.field);

    printCommand.addEmptyLine();

    addItemColumn(receiptData.items);

    printCommand.addLine();

    addPayments(receiptData.payments);

    printCommand.addEmptyLine(line: 2);

    addMultiLine(receiptData.footer);

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
        ratio: 2,
      ),
      TextColumn(
        text: 'Discount',
        ratio: 2,
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
      printCommand.addTextRow([
        TextColumn(
          text: item.price,
          ratio: 2,
        ),
        TextColumn(
          text: item.discount.toStringAsFixed(2),
          ratio: 2,
        ),
        TextColumn(
          text: item.qty.toString(),
          ratio: 1,
        ),
        TextColumn(text: item.amount, ratio: 2, alignment: PosAlign.right),
      ]);
    }
  }

  void addPayments(List<RPayment> payments) {
    for (var payment in payments) {
      printCommand.addTextRow([
        TextColumn(
            text: payment.text,
            ratio: 3,
            alignment: PosAlign.right,
            bold: payment.bold),
        TextColumn(
            text: payment.amount,
            ratio: 1,
            alignment: PosAlign.right,
            bold: payment.bold)
      ]);
      if (payment.linebreak) {
        printCommand.addLine();
      }
    }
  }
}
