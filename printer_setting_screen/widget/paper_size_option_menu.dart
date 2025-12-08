import 'package:flutter/widgets.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

import '../../../../core_utils/tunai_navigator/tunai_navigator.dart';
import '../../../../tunai_style/widgets/dialog/custom_dialog/src/custom_dialog.dart';
import '../../../../tunai_style/widgets/dialog/popup_menu/tunai_popup_menu/tunai_popup_menu.dart';
import '../../super_printer.dart';

class PaperSizeOptionMenu {
  final BuildContext context;
  final void Function(PaperSize paperSize) onSizeChanged;

  PaperSizeOptionMenu({
    required this.onSizeChanged,
    required this.context,
  });

  Future<void> show() async {
    late final List<TunaiPopupMenuItem> items = allPaperSizes
        .map((paperSize) => TunaiPopupMenuItem(
            title: paperSize.name,
            onPressed: () {
              TunaiNavigator.pop();
              onSizeChanged(paperSize);
            }))
        .toList();

    return TunaiPopupMenu(
      items: items,
      alignTargetWidget: AlignTargetWidget.centerBottomRight,
    ).show(
      context,
      navigatorContext: TunaiNavigator.currentContext,
    );
  }
}
