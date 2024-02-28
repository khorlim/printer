import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/print_command_adapter.dart';

abstract class AbstractReceipt {
  final PType printerType;
  final ReceiptData receiptData;
  final PaperSize paperSize;

  AbstractReceipt({
    required this.printerType,
    required this.receiptData,
    required this.paperSize,
  });

  late final PrintCommandAdapter printCommand =
      PrintCommandAdapter(printerType: printerType, paperSize: paperSize);

  Future<PrintCommandAdapter> getReceipt({bool openDrawer = false});
}
