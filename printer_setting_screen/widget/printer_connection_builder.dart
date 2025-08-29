import 'package:flutter/material.dart';

import '../../src/model/custom_printer_model.dart';

class PrinterConnectionBuilder extends StatelessWidget {
  final Widget Function(
          BuildContext context, PStatus printerStatus, CustomPrinter? printer)
      builder;
  const PrinterConnectionBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, PStatus.none, null);
  }
}
