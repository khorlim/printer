import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/print_commander/super_print_commander.dart';
import 'package:tunaipro/extra_utils/printer/src/receipt_commands/general_receipt.dart';
import 'package:tunaipro/extra_utils/printer/src/receipt_commands/workslip_receipt.dart';

enum ReceiptType { beauty, car, optic, spa, workslip }

class ReceiptFactory {
  static SuperPrintCommander getReceipt({
    required ReceiptType receiptType,
    required ReceiptData receiptData,
    required PaperSize paperSize,
    bool openDrawer = false,
    PType printerType = PType.btPrinter,
    double? iconSize,
  }) {
    switch (receiptType) {
      case ReceiptType.workslip:
        return WorkSlipReceipt(
          printerType: printerType,
          receiptData: receiptData,
          paperSize: paperSize,
        ).getPrintCommand(openDrawer: openDrawer);

      default:
        return GeneralReceipt(
          printerType: printerType,
          receiptData: receiptData,
          paperSize: paperSize,
          iconSize: iconSize,
        ).getPrintCommand(openDrawer: openDrawer);
    }
  }
}
