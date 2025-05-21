import 'package:flutter/material.dart';
import '../../super_printer.dart';
import '../../../../tunai_style/style_imports.dart';

class PrinterInfoWidget extends StatefulWidget {
  const PrinterInfoWidget({super.key});

  @override
  State<PrinterInfoWidget> createState() => _PrinterInfoWidgetState();
}

class _PrinterInfoWidgetState extends State<PrinterInfoWidget> {
  final SuperPrinter superPrinter = SuperPrinter();

  late Future getPrinterFuture;
  bool status = false;

  @override
  void initState() {
    super.initState();
    getPrinterFuture = getSelectedPrinter();
  }

  Future<CustomPrinter?> getSelectedPrinter() async {
    status = await superPrinter.checkStatus();
    // print('printer info : $status : ${superPrinter.currentPrinter}');
    return superPrinter.currentPrinter;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: superPrinter.printerStatusStream,
        builder: (context, snapshot) {
          PStatus status = snapshot.data ?? PStatus.none;
          CustomPrinter? printer = superPrinter.currentPrinter;
          bool failedToConnect = status == PStatus.none && printer != null;
          if (snapshot.hasError || printer == null) {
            return const EmptyLabelText(
              label: 'None',
            );
          } else {
            return Row(
              children: [
                Text(
                  printer.name,
                  style: context.text.primary.copyWith(
                    color: context.colorScheme.primary,
                  ),
                ),
                if (failedToConnect)
                  Icon(
                    CupertinoIcons.xmark,
                    color: Colors.red,
                    size: 18,
                  )
              ],
            );
          }
        });
  }
}
