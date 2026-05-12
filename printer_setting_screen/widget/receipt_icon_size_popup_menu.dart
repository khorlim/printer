import 'package:flutter/cupertino.dart';
import 'package:tunai_widget/tunai_option_menu.dart';

import '../utils/receipt_icon_size_storage.dart';

class ReceiptIconSizePopupMenu {
  final ReceiptIconSize? selectedSize;
  final void Function(ReceiptIconSize size) onSelected;

  const ReceiptIconSizePopupMenu({
    this.selectedSize,
    required this.onSelected,
  });

  void show(BuildContext context) {
    final items = ReceiptIconSize.values
        .map(
          (e) => TunaiOptionMenuSelection(
            isSelected: e == selectedSize,
            title: e.displayName,
            icon: const Icon(CupertinoIcons.doc_text),
            onPressed: () {
              onSelected(e);
            },
          ),
        )
        .toList();

    TunaiOptionMenu(
      items: items,
    ).show(context: context);
  }
}
