import 'package:flutter/cupertino.dart';

import '../../../../tunai_style/widgets/dialog/custom_dialog/src/custom_dialog.dart';
import '../../../../tunai_style/widgets/dialog/popup_menu/tunai_popup_menu/tunai_popup_menu.dart';
import '../utils/receipt_icon_size_storage.dart';

class ReceiptIconSizePopupMenu {
  final ReceiptIconSize? selectedSize;
  final void Function(ReceiptIconSize size) onSelected;

  const ReceiptIconSizePopupMenu({
    this.selectedSize,
    required this.onSelected,
  });

  void show(
    BuildContext context, {
    AlignTargetWidget alignTargetWidget = AlignTargetWidget.centerBottomRight,
  }) {
    final items = ReceiptIconSize.values
        .map(
          (e) => TunaiPopupMenuItem(
            isSelected: e == selectedSize,
            title: e.displayName,
            iconData: CupertinoIcons.doc_text,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              onSelected(e);
            },
          ),
        )
        .toList();

    TunaiPopupMenu(
      items: items,
      alignTargetWidget: alignTargetWidget,
    ).show(context);
  }
}
