import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';

import '../data_models/car_receipt.dart';
import '../data_models/print_data.dart';
import '../data_models/spa_receipt.dart';
import '../data_models/spa_workslip.dart';
import 'print_commands/spa_print_command.dart';
import 'print_commands/spa_workslip_command.dart';

class LocalPrint {
  final BuildContext context;
  final String addr;
  final Function searchAndStartPrint;

  LocalPrint(
      {required this.context,
      required this.addr,
      required this.searchAndStartPrint});

  Future<void> print({required PrintData printData}) async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(addr, port: 9100);

    if (res == PosPrintResult.success) {
      switch (printData.runtimeType) {
        case SpaReceiptData:
          SpaReceiptData spaReceiptData = printData as SpaReceiptData;
          await spaReceipt(context, printer, spaReceiptData);
          break;
        case SpaWorkSlipData:
          SpaWorkSlipData spaWorkSlipData = printData as SpaWorkSlipData;
          await spaWorkSlip(context, printer, spaWorkSlipData);
          break;
        case CarReceiptData:
          await carReceipt(context, printer, printData as CarReceiptData);
          break;
      }
      printer.disconnect();
    } else {
      searchAndStartPrint();
    }
  }
}
