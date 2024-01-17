import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/bit_map_text_helper.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/text_column.dart';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

enum FontSizeType { normal, big }

class PrintCommandAdapter {
  final PType printerType;
  final PaperSize paperSize;
  PrintCommandAdapter(
      {required this.printerType, this.paperSize = PaperSize.mm80}) {}

  Future<void> initialize({String? imagePath}) async {
    try {
      _profile = await CapabilityProfile.load();
      _generator = Generator(paperSize, _profile!);
      if (imagePath != null) {
        _image = await _getImageFromUrl(imagePath);
      }
      _printCommands.push({'enableEmphasis': true});
      _printCommands.push({'appendFontStyle': 'Menlo'});
    } catch (e) {
      debugPrintStack();
      throw Exception('Failed to load profile. $e');
    }
  }

  CapabilityProfile? _profile;
  Generator? _generator;
  img.Image? _image;

  late final BitmapTextHelper _textHelper =
      BitmapTextHelper(printerType: printerType, paperSize: paperSize);

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

  void addImage(String imagePath) async {
    if (_generator == null) {
      throw Exception('Profile must be loaded before using the class.');
    }

    if (_image == null) {
      throw Exception('Image must be initialized before this function.');
    }

    _printCommands.appendBitmap(
      path: imagePath,
      width: 576 ~/ 2,
      absolutePosition: (576 ~/ 2) ~/ 2,
      bothScale: true,
    );

    _bytes += _generator!.image(_image!);
  }

  void addEmptyLine({int line = 1}) {
    _printCommands.appendBitmapText(text: _textHelper.emptyLine(line: line));
    _bytes += _generator!.feed(line);
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
        containsChinese: true,
        styles: PosStyles(
          height: _getFontPosTextSize(fontSizeType),
          width: _getFontPosTextSize(fontSizeType),
          align: alignment,
          bold: bold,
        ),
        linesAfter: linesAfter);
  }

  void addLine() {
    if (_generator == null) {
      throw Exception('Profile must be loaded before using the class.');
    }

    _printCommands.appendBitmapText(text: _textHelper.line());

    _bytes += _generator!.text(
      _textHelper.line(),
    );
  }

  void addTextRow(
    List<TextColumn> textList, {
    int linesAfter = 0,
  }) {
    if (_generator == null) {
      throw Exception('Profile must be loaded before using the class.');
    }

    bool bold = textList.any((element) => element.bold);

    if (bold) {
      _printCommands
          .push({'appendEmphasis': _textHelper.row(textList, bold: bold)});
    } else {
      _printCommands.appendBitmapText(text: _textHelper.row(textList));
    }

    List<PosColumn> posColumnList = textList.map((textColumn) {
      int max = 12;
      int totalR = textList.fold(0, (total, text) => total += text.ratio);
      int width = ((textColumn.ratio / totalR) * max).round();
      return textColumn.toPosColumn(width);
    }).toList();

    // _bytes += _generator!.row(posColumnList, multiLine: false);
    _bytes += _generator!.text(_textHelper.row(textList),
        styles: PosStyles(bold: bold), containsChinese: true);
  }

  void openCashDrawer() {
    _printCommands.openCashDrawer(1);
    _bytes += _generator!.drawer();
  }

  Future<img.Image> _getImageFromUrl(String path) async {
    try {
      img.Image? image;

      final response = await http.get(Uri.parse(path));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        image = img.decodeImage(Uint8List.fromList(bytes));
        image = img.copyResize(image!,
            backgroundColor: img.ColorUint8.rgb(255, 255, 255),
            width: 558 ~/ 2,
            maintainAspect: true,
            interpolation: img.Interpolation.linear);
      } else {
        debugPrint('-----Failed to load image from url.');
      }

      return image!;
    } catch (e) {
      debugPrint('-----Failed to get image from url. $e.');
      rethrow;
    }
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
