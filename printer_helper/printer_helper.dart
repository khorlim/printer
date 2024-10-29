import '../../../engine/receipt/model/receipt_data.dart';
import '../src/print_commander/abstract_print_commander.dart';
import '../super_printer.dart';

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
