import 'package:collection/collection.dart';
import 'package:shared_pref_helper/shared_pref_helper.dart';

import '../../../../tunai_style/translation/strings.g.dart';

enum ReceiptIconSize {
  none,
  small,
  medium,
  large,
  ;

  String get displayName => switch (this) {
        none => t.none,
        small => t.small,
        medium => t.medium,
        large => t.large,
      };

  factory ReceiptIconSize.fromString(String name) {
    return values.firstWhereOrNull(
          (element) => element.name == name,
        ) ??
        ReceiptIconSize.medium;
  }

  double get size => switch (this) {
        none => 0,
        small => 130,
        medium => 260,
        large => 310,
      };
}

class ReceiptIconSizeStorage
    extends AbstractSharedPrefStorage<ReceiptIconSize> {
  @override
  String convertDataToString(ReceiptIconSize data) {
    return data.name;
  }

  @override
  ReceiptIconSize convertStringToData(String data) {
    return ReceiptIconSize.fromString(data);
  }

  @override
  String get key => 'receipt_icon_size';
}
