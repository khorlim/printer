import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/src/super_print_command.dart';
import 'package:tunaipro/extra_utils/printer/super_printer.dart';

class PrinterHelper {
  PrinterHelper._();
  factory PrinterHelper() => _instance;
  static final PrinterHelper _instance = PrinterHelper._();

  final SuperPrinter superPrinter = SuperPrinter();

  Future<bool> printSaleReceipt({
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

  Future<bool> printCustomCommand(SuperPrintCommand printCommand) async {
    return superPrinter.startPrint(printCommand);
  }

  Future<void> openDrawer() {
    return superPrinter.openDrawer();
  }
}
