import 'package:flutter/widgets.dart';

import '../../../../translation/strings.g.dart';

class PrinterInfoWidget extends StatelessWidget {
  const PrinterInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      t.noPrinter,
    );
  }
}
