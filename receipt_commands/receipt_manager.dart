import 'package:printer_test/printer/model/custom_printer_model.dart';
import 'package:printer_test/printer/print_command_adapter.dart';
import 'package:printer_test/printer/receipt_commands/beauty_receipts.dart';

enum ReceiptType { beauty, car, optic, spa }

class ReceiptManager {
  static Future<PrintCommandAdapter> getReceipt(ReceiptType receiptType,
      {PType printerType = PType.btPrinter}) async {
    switch (receiptType) {
      case ReceiptType.car:
        return PrintCommandAdapter(printerType: printerType);

      case ReceiptType.optic:
        return PrintCommandAdapter(printerType: printerType);

      case ReceiptType.spa:
        return PrintCommandAdapter(printerType: printerType);

      default:
        return await BeautyReceipt.getReceipt(printerType: printerType);
    }
  }
}
