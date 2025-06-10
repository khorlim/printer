import 'package:flutter/widgets.dart';

import '../../../../tunai_style/extension/build_context_extension.dart';
import '../../../../tunai_style/translation/strings.g.dart';

class PrinterInfoWidget extends StatelessWidget {
  const PrinterInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      t.noPrinter,
      style: context.text.primary.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
