import 'package:flutter/material.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';

import '../data_models/car_receipt.dart';
import '../data_models/print_data.dart';
import '../data_models/spa_receipt.dart';
import '../data_models/spa_workslip.dart';
import '../printer_utils/dialogs.dart';
import '../printer_utils/utils.dart';
import 'print_commands/spa_receipt_command.dart';
import 'print_commands/spa_workslip_command.dart';

class StarPrinter {
  final BuildContext context;
  final String portName;
  final String modelName;
  final Function searchAndStartPrint;

  StarPrinter({
    required this.context,
    required this.portName,
    required this.modelName,
    required this.searchAndStartPrint,
  });

  Future<void> startPrint({required PrintData printData}) async {
    bool format58mm = false;
    // modelName.contains('POP10');
    try {
      PrintCommands? commands;

      switch (printData.runtimeType) {
        case SpaReceiptData:
          commands = spaReceipt(
              format58mm: format58mm, printData: printData as SpaReceiptData);
          break;
        case SpaWorkSlipData:
          commands = spaWorkSlip(
              format58mm: format58mm, printData: printData as SpaWorkSlipData);
          break;
        case CarReceiptData:
          commands = carReceipt(
              format58mm: format58mm, printData: printData as CarReceiptData);
          break;
      }

      if (commands == null) {
        print('star printer commands is null, return');
        return;
      }

      PrinterResponseStatus responseStatus = await StarPrnt.sendCommands(
        portName: portName,
        emulation: emulationFor(modelName),
        printCommands: commands,
      );

      if (responseStatus.isSuccess) {
      } else {}
    } catch (e) {
      searchAndStartPrint();
    }
  }
}
