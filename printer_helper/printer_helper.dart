import '../../../data/engine/receipt/model/receipt_data.dart';
import '../printer_setting_screen/utils/receipt_icon_size_storage.dart';
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
    final ReceiptIconSizeStorage iconSizeStorage = ReceiptIconSizeStorage();
    final iconSize = iconSizeStorage.fetch() ?? ReceiptIconSize.medium;
    bool success = await superPrinter.printReceipt(
      receiptData: receiptData,
      receiptType: receiptType,
      openDrawer: openDrawer,
      iconSize: iconSize.size,
    );
    return success;
  }

  static Future<bool> printCustomCommand(
    AbstractPrintCommander commander,
  ) async {
    return superPrinter.printCustomCommand(commander);
  }

  static Future<void> openDrawer() {
    return superPrinter.openDrawer();
  }
}
