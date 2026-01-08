import 'dart:io';

import '../../../data/engine/receipt/model/receipt_data.dart';
import '../src/print_commander/abstract_print_commander.dart';
import '../super_printer.dart';

class PrinterHelper {
  static final SuperPrinter superPrinter = SuperPrinter();

  static bool get isPrinterConnected => false;

  static Future<bool> printSaleReceipt({
    required ReceiptData receiptData,
    ReceiptType receiptType = ReceiptType.beauty,
    bool openDrawer = false,
  }) async {
    return false;
    // bool success = await superPrinter.printReceipt(
    //   receiptData: receiptData,
    //   receiptType: receiptType,
    //   openDrawer: openDrawer,
    // );
    // return success;
  }

  static Future<bool> printCustomCommand(
      AbstractPrintCommander commander) async {
    return false;
    // return superPrinter.printCustomCommand(commander);
  }

  static Future<void> openDrawer() {
    return Future.value();
    // return superPrinter.openDrawer();
  }

  static Future<File?> getPdfFile(ReceiptData receiptData) async {
    return null;
  }
}
