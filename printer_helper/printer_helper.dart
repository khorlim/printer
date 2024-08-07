import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/src/print_commander/abstract_print_commander.dart';
import 'package:tunaipro/extra_utils/printer/src/print_commander/super_print_commander.dart';
import 'package:tunaipro/extra_utils/printer/super_printer.dart';

class PrinterHelper {
  static final SuperPrinter superPrinter = SuperPrinter();

  static bool get isPrinterConnected => superPrinter.currentPrinter != null;

  static Future<bool> printSaleReceipt({
    required ReceiptData receiptData,
    ReceiptType receiptType = ReceiptType.beauty,
    bool openDrawer = false,
  }) async {
    bool success = await superPrinter.printReceipt(
      receiptData: receiptData,
      receiptType: receiptType,
      openDrawer: openDrawer,
    );
    return success;
  }

  static Future<bool> printCustomCommand(
      AbstractPrintCommander commander) async {
    return superPrinter.printCustomCommand(commander);
  }

  static Future<void> openDrawer() {
    return superPrinter.openDrawer();
  }
}
