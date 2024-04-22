import 'package:flutter/material.dart';
import 'package:tunaipro/theme/style_imports.dart';

import 'super_printer.dart';

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
    return superPrinter.currentPrinter;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getPrinterFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            CustomPrinter? printer = snapshot.data;
            if (snapshot.hasError || printer == null) {
              return const TText(
                'None',
                color: MyColor.grey,
              );
            } else {
              return Row(
                children: [
                  TText(
                    printer.name,
                    color: MyColor.blue,
                  ),
                  if (!status)
                    Icon(
                      CupertinoIcons.xmark,
                      color: Colors.red,
                      size: 18,
                    )
                ],
              );
            }
          } else {
            return const CupertinoActivityIndicator();
          }
        });
  }
}
