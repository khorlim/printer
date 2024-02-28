import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/super_printer.dart';
import 'package:tunaipro/general_module/order_module/import_path.dart';

Future<bool> printReceipt({
  required BuildContext context,
  required ReceiptData receiptData,
  ReceiptType receiptType = ReceiptType.beauty,
  bool openDrawer = false,
}) async {
  final SuperPrinter superPrinter = SuperPrinter();
  bool success = await superPrinter.startPrint(
      receiptData: receiptData,
      receiptType: receiptType,
      openDrawer: openDrawer);
  return success;
}
