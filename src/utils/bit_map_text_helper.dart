import 'dart:io';

import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import '../model/custom_printer_model.dart';
import '../print_commander/super_print_commander.dart';

import 'text_column.dart';

class BitmapTextHelper {
  final PType printerType;
  final PaperSize paperSize;
  late int _maxWidth = _getMaxWidth();
  BitmapTextHelper({required this.printerType, required this.paperSize}) {}
  String text(
    String text, {
    PosAlign alignment = PosAlign.left,
    int linesAfter = 0,
    FontSizeType fontSizeType = FontSizeType.normal,
  }) {
    _maxWidth = _getMaxWidth(fontSizeType: fontSizeType);

    String formatText = text;
    switch (alignment) {
      case PosAlign.left:
        formatText = text;
        break;
      case PosAlign.center:
        formatText = _centerText(text);
        break;
      case PosAlign.right:
        formatText = _rightAlignText(text);
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
    int remainingWidth = _maxWidth;
    int totalColumns = textColumns.length;

    for (int i = 0; i < textColumns.length; i++) {
      final TextColumn textColumn = textColumns[i];
      String content = textColumn.text;

      // Calculate space for this column, ensuring we don't exceed remaining width
      int addSpace = i == totalColumns - 1
          ? remainingWidth
          : (textColumn.ratio / totalR * _maxWidth).floor();

      remainingWidth -= addSpace;

      // Handle text overflow based on column's overflow setting
      if (content.length > addSpace) {
        switch (textColumn.overflow) {
          case ColumnOverflow.truncate:
            content = content.substring(0, addSpace - 3) + '...';
            break;
          case ColumnOverflow.wrap:
            List<String> wrappedLines = _wrapText(content, addSpace);
            if (wrappedLines.length > 1) {
              // If text wraps to multiple lines, we need to handle the entire row differently
              return _handleWrappedRow(
                  textColumns, i, wrappedLines, addSpace, bold, linesAfter);
            }
            content = wrappedLines[0];
            break;
        }
      }

      if (textColumn.alignment == PosAlign.right) {
        row += content.padLeft(addSpace);
      } else if (textColumn.alignment == PosAlign.left) {
        row += content.padRight(addSpace);
      } else if (textColumn.alignment == PosAlign.center) {
        int totalSpace = addSpace - content.length;
        int spaceLeft = totalSpace ~/ 2;
        int spaceRight = totalSpace - spaceLeft; // Handle odd spaces
        row += (' ' * spaceLeft) + content + (' ' * spaceRight);
      }
    }

    return row + ('\n' * (linesAfter));
  }

  String _handleWrappedRow(List<TextColumn> textColumns, int wrappedColumnIndex,
      List<String> wrappedLines, int columnWidth, bool bold, int linesAfter) {
    String result = '';
    int totalR = textColumns.fold(0, (total, text) => total += text.ratio);
    int remainingWidth = _maxWidth;

    // Process each wrapped line
    for (int lineIndex = 0; lineIndex < wrappedLines.length; lineIndex++) {
      String row = '';
      remainingWidth = _maxWidth;

      for (int i = 0; i < textColumns.length; i++) {
        final TextColumn textColumn = textColumns[i];
        String content;
        int addSpace;

        if (i == wrappedColumnIndex) {
          // This is the wrapped column
          content =
              lineIndex < wrappedLines.length ? wrappedLines[lineIndex] : '';
          addSpace = columnWidth;
        } else {
          // For other columns, only show content in the first line
          content = lineIndex == 0 ? textColumn.text : '';
          addSpace = i == textColumns.length - 1
              ? remainingWidth
              : (textColumn.ratio / totalR * _maxWidth).floor();
        }

        remainingWidth -= addSpace;

        if (textColumn.alignment == PosAlign.right) {
          row += content.padLeft(addSpace);
        } else if (textColumn.alignment == PosAlign.left) {
          row += content.padRight(addSpace);
        } else if (textColumn.alignment == PosAlign.center) {
          int totalSpace = addSpace - content.length;
          int spaceLeft = totalSpace ~/ 2;
          int spaceRight = totalSpace - spaceLeft;
          row += (' ' * spaceLeft) + content + (' ' * spaceRight);
        }
      }
      result += row + '\n';
    }

    return result + ('\n' * (linesAfter));
  }

  List<String> _wrapText(String text, int maxWidth) {
    List<String> words = text.split(' ');
    List<String> lines = [];
    String currentLine = '';

    for (String word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + word.length + 1 <= maxWidth) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  List<String> _divideTextIntoLines(String text) {
    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + word.length + 1 <= _maxWidth) {
        currentLine += ' ' + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  String _centerLine(String line) {
    // Center a single line
    return ' ' * ((_maxWidth - line.length) ~/ 2) + line;
  }

  int _getMaxWidth({
    FontSizeType fontSizeType = FontSizeType.normal,
    bool bold = false,
  }) {
    if (printerType == PType.starPrinter) {
      if (paperSize == PaperSize.mm58) {
        switch (fontSizeType) {
          case FontSizeType.normal:
            // if (bold) {
            //   return 38;
            // }

            return 58;
          case FontSizeType.big:
            return 29;
        }
      } else {
        switch (fontSizeType) {
          case FontSizeType.normal:
            // if (bold) {
            //   return 38;
            // }

            return Platform.isAndroid ? 41 : 39;
          case FontSizeType.big:
            return Platform.isAndroid ? 24 : 23; //ori 23
        }
      }
    }

    if (paperSize == PaperSize.mm58) {
      return 32;
    } else {
      return 48;
    }
  }
}
