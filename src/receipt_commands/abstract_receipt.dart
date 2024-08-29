import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import '../../../../engine/receipt/model/receipt_data.dart';
import '../model/custom_printer_model.dart';
import '../print_commander/super_print_commander.dart';

abstract class AbstractReceipt {
  final PType printerType;
  final PaperSize paperSize;

  AbstractReceipt({
    required this.printerType,
    required this.paperSize,
  });

  late final SuperPrintCommander printCommand =
      SuperPrintCommander(printerType: printerType, paperSize: paperSize);

  SuperPrintCommander getPrintCommand({bool openDrawer = false});
}
