import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import '../model/custom_printer_model.dart';
import '../print_commander/super_print_commander.dart';

import 'text_column.dart';

class BitmapTextHelper {
  final PType printerType;
  final PaperSize paperSize;
  late int _maxWidth = _getMaxWidth();
  BitmapTextHelper({required this.printerType, required this.paperSize}) {}
  String text(String text,
      {PosAlign alignment = PosAlign.left,
      int linesAfter = 0,
      FontSizeType fontSizeType = FontSizeType.normal}) {
    _maxWidth = _getMaxWidth(fontSizeType: fontSizeType);

    String formatText = text;
    switch (alignment) {
      case PosAlign.left:
        formatText = '$text';
        break;
      case PosAlign.center:
        formatText = '${_centerText(text)}';
        break;
      case PosAlign.right:
        formatText = '${_rightAlignText(text)}';
        break;
    }
    return formatText + ('\n' * (linesAfter - 1));
  }

  String emptyLine({int line = 1}) {
    return '          \n' * line;
  }

  String line() {
    return '-' * _maxWidth;
  }

  String _centerText(String text) {
    if (text.length > _maxWidth) {
      List<String> dividedLines = _divideTextIntoLines(text);
      List<String> centeredLines =
          dividedLines.map((line) => _centerLine(line)).toList();
      return centeredLines.join('\n');
    } else {
      // If the text is not longer than _maxWidth, center it directly
      return _centerLine(text);
    }
  }

  String _rightAlignText(String text) {
    int leftPadding = _maxWidth - text.length;
    return ' ' * leftPadding + text;
  }

  String row(List<TextColumn> textColumns,
      {bool bold = false, int linesAfter = 0}) {
    _maxWidth = _getMaxWidth(bold: bold);

    if (textColumns.isEmpty) {
      return '';
    }
    int totalR = textColumns.fold(0, (total, text) => total += text.ratio);

    String row = '';

    int countingSpace = 0;

    for (int i = 0; i < textColumns.length; i++) {
      final TextColumn textColumn = textColumns[i];
      String content = textColumns[i].text;
      int addSpace = (textColumn.ratio / totalR * _maxWidth).ceil();

      if (countingSpace + addSpace >= _maxWidth) {
        addSpace = _maxWidth - countingSpace;
      }
      countingSpace += addSpace;
      if (textColumn.alignment == PosAlign.right) {
        row += content.padLeft(addSpace);
      } else if (textColumn.alignment == PosAlign.left) {
        row += content.padRight(addSpace);
      } else if (textColumn.alignment == PosAlign.center) {
        int spaceLeft = (addSpace - content.length) ~/ 2;
        row += (' ' * spaceLeft) + content + (' ' * spaceLeft);
      }
    }

    if (bold) {
      print(row.length);
    }

    return '$row' + ('\n' * (linesAfter));
  }

  List<String> _divideTextIntoLines(String text) {
    // Logic to divide the text into lines based on _maxWidth
    // You can implement this based on your requirements
    // For example, you can split the text into lines of length _maxWidth
    int startIndex = 0;
    List<String> lines = [];
    while (startIndex < text.length) {
      int endIndex = startIndex + _maxWidth;
      String line = text.substring(
          startIndex, (endIndex > text.length ? text.length : endIndex));
      lines.add(line);
      startIndex += _maxWidth;
    }
    return lines;
  }

  String _centerLine(String line) {
    // Center a single line
    return ' ' * ((_maxWidth - line.length) ~/ 2) + line;
  }

  int _getMaxWidth(
      {FontSizeType fontSizeType = FontSizeType.normal, bool bold = false}) {
    if (printerType == PType.starPrinter) {
      switch (fontSizeType) {
        case FontSizeType.normal:
          // if (bold) {
          //   return 38;
          // }

          return 39;
        case FontSizeType.big:
          return 23;
      }
    } else if (paperSize == PaperSize.mm58) {
      return 32;
    } else {
      return 48;
    }
  }
}
