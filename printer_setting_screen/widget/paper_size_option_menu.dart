import 'package:flutter/widgets.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tunai_widget/tunai_option_menu.dart';

import '../../super_printer.dart';

class PaperSizeOptionMenu {
  final BuildContext context;
  final void Function(PaperSize paperSize) onSizeChanged;

  PaperSizeOptionMenu({
    required this.onSizeChanged,
    required this.context,
  });

  Future<void> show() async {
    late final List<TunaiOptionMenuButton> items = allPaperSizes
        .map((paperSize) => TunaiOptionMenuButton(
            title: paperSize.name,
            onPressed: () {
              onSizeChanged(paperSize);
            }))
        .toList();

    return TunaiOptionMenu(
      items: items,
    ).show(context: context);
  }
}
