import 'package:flutter/cupertino.dart';
import 'package:tunai_widget/tunai_widget.dart';

import '../../../../tunai_style/common_widgets/typo/text/empty_label_text.dart';
import '../../super_printer.dart';

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
                TunaiText(
                  printer.name,
                  color: context.color.primary,
                ),
                if (failedToConnect)
                  Icon(
                    CupertinoIcons.xmark,
                    color: context.color.error,
                    size: 18,
                  ),
              ],
            );
          }
        });
  }
}
