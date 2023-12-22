import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/print_command_adapter.dart';
import 'package:tunaipro/extra_utils/printer/src/receipt_commands/general_receipt.dart';

enum ReceiptType { beauty, car, optic, spa }

class ReceiptManager {
  static Future<PrintCommandAdapter> getReceipt(
      {required ReceiptType receiptType,
      required ReceiptData receiptData,
      PType printerType = PType.btPrinter}) async {
    switch (receiptType) {
      case ReceiptType.car:
        return PrintCommandAdapter(printerType: printerType);

      case ReceiptType.optic:
        return PrintCommandAdapter(printerType: printerType);

      case ReceiptType.spa:
        return PrintCommandAdapter(printerType: printerType);

      default:
        return await GeneralReceipt(
                printerType: printerType, receiptData: receiptData)
            .getReceipt();
    }
  }
}
