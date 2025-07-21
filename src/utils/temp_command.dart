import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

import 'text_column.dart';

class TempCommand {}

class TextCommand extends TempCommand {
  final String text;
  final PosStyles style;
  final int linesAfter;
  TextCommand(this.text, {required this.style, required this.linesAfter});
}

class ImageCommand extends TempCommand {
  final String imagePath;
  double? imageSize;
  ImageCommand(
    this.imagePath, {
    this.imageSize,
  });
}

class EmptyLineCommand extends TempCommand {
  final int line;

  EmptyLineCommand(this.line);
}

class LineCommand extends TempCommand {}

class TextRowCommand extends TempCommand {
  final PosStyles style;
  final List<TextColumn> textList;

  TextRowCommand(this.textList, {required this.style});
}

class QRCodeCommand extends TempCommand {
  final String qrCode;
  QRCodeCommand(this.qrCode);
}

class OpenCashDrawerCommand extends TempCommand {}
