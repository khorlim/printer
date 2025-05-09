import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

enum ColumnOverflow { truncate, wrap }

class TextColumn {
  final String text;
  final int ratio;
  final bool bold;
  final PosAlign alignment;
  final ColumnOverflow overflow;

  TextColumn(
      {required this.text,
      required this.ratio,
      this.bold = false,
      this.alignment = PosAlign.left,
      this.overflow = ColumnOverflow.truncate});

  PosColumn toPosColumn(int width) {
    return PosColumn(
      text: text,
      styles: PosStyles(bold: bold, align: alignment),
      width: width,
    );
  }
}
