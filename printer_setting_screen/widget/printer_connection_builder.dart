import 'package:flutter/material.dart';

import '../../src/model/custom_printer_model.dart';
import '../../src/super_printer.dart';

class PrinterConnectionBuilder extends StatefulWidget {
  final Widget Function(
          BuildContext context, PStatus printerStatus, CustomPrinter? printer)
      builder;
  const PrinterConnectionBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<PrinterConnectionBuilder> createState() =>
      _PrinterConnectionBuilderState();
}

class _PrinterConnectionBuilderState extends State<PrinterConnectionBuilder> {
  final superPrinter = SuperPrinter();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: superPrinter.printerStatusStream,
      builder: (context, snapshot) {
        final status = superPrinter.status;
        final printer = superPrinter.currentPrinter;
        return widget.builder(
          context,
          status,
          printer,
        );
      },
    );
  }
}
