import 'package:flutter/cupertino.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:printer_test/printer/model/custom_printer_model.dart';
import 'package:printer_test/printer/utils/bit_map_text_helper.dart';
import 'package:printer_test/printer/utils/text_column.dart';

enum FontSizeType { normal, big }

class PrintCommandAdapter {
  final PType printerType;
  PrintCommandAdapter({required this.printerType}) {}

  Future<void> loadProfile() async {
    try {
      _profile = await CapabilityProfile.load();
      _generator = Generator(_paperSize, _profile!);
    } catch (e) {
      debugPrintStack();
      throw Exception('Failed to load profile. $e');
    }
  }

  final PaperSize _paperSize = PaperSize.mm80;
  late final BitmapTextHelper _textHelper =
      BitmapTextHelper(printerType: printerType);
  late Future _loadProfileFuture;
  CapabilityProfile? _profile;
  Generator? _generator;

  PrintCommands _printCommands = PrintCommands();
  String _bitMapText = '';

  List<int> _bytes = [];

  List<int> get bytes {
    _bytes += _generator!.cut();
    return _bytes;
  }

  PrintCommands get starPrintCommands {
    _printCommands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);
    return _printCommands;
  }

  void addTextLine(String text,
      {PosAlign alignment = PosAlign.left,
      bool bold = false,
      int linesAfter = 0,
      FontSizeType fontSizeType = FontSizeType.normal}) {
    if (_generator == null) {
      throw Exception('Profile must be loaded before using the class.');
    }

    _printCommands.appendBitmapText(
        fontSize: _getFontSize(fontSizeType),
        text: _textHelper.text(text,
            alignment: alignment,
            linesAfter: linesAfter,
            fontSizeType: fontSizeType));

    _bytes += _generator!.text(text,
        styles: PosStyles(
          height: _getFontPosTextSize(fontSizeType),
          width: _getFontPosTextSize(fontSizeType),
          align: alignment,
          bold: bold,
        ),
        linesAfter: linesAfter);
  }

  void addTextRow(
    List<TextColumn> textList, {
    int linesAfter = 0,
  }) {
    if (_generator == null) {
      throw Exception('Profile must be loaded before using the class.');
    }

    _printCommands.appendBitmapText(text: _textHelper.row(textList));

    List<PosColumn> posColumnList = textList.map((textColumn) {
      int max = 12;
      int totalR = textList.fold(0, (total, text) => total += text.ratio);
      int width = ((textColumn.ratio / totalR) * max).round();
      return textColumn.toPosColumn(width);
    }).toList();

    // _bytes += _generator!.row(posColumnList, multiLine: false);
    _bytes += _generator!.text(
      _textHelper.row(textList),
    );
  }

  int _getFontSize(FontSizeType fontSizeType) {
    switch (fontSizeType) {
      case FontSizeType.big:
        return 20;
      case FontSizeType.normal:
        return 12;
    }
  }

  PosTextSize _getFontPosTextSize(FontSizeType fontSizeType) {
    switch (fontSizeType) {
      case FontSizeType.big:
        return PosTextSize.size2;
      case FontSizeType.normal:
        return PosTextSize.size1;
    }
  }
}
