import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

class TextColumn {
  final String text;
  final int ratio;
  final bool bold;
  final PosAlign alignment;

  TextColumn(
      {required this.text,
      required this.ratio,
      this.bold = false,
      this.alignment = PosAlign.left});

  PosColumn toPosColumn(int width) {
    return PosColumn(
      text: text,
      styles: PosStyles(bold: bold, align: alignment),
      width: width,
    );
  }
}
