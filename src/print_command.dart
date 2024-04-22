import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/bit_map_text_helper.dart';
import 'package:tunaipro/extra_utils/printer/src/utils/text_column.dart';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

import 'utils/temp_command.dart';

enum FontSizeType { normal, big }

class SuperPrintCommand {
  final PType printerType;
  final PaperSize paperSize;
  SuperPrintCommand({
    required this.printerType,
    this.paperSize = PaperSize.mm80,
  }) {
    _printCommands.push({'enableEmphasis': true});
    _printCommands.push({'appendFontStyle': 'Menlo'});
  }
  late final BitmapTextHelper _textHelper =
      BitmapTextHelper(printerType: printerType, paperSize: paperSize);

  final PrintCommands _printCommands = PrintCommands();

  List<TempCommand> tempCommands = [];

  Future<List<int>> getBytes() async {
    CapabilityProfile profile = await CapabilityProfile.load();
    Generator generator = Generator(paperSize, profile);
    List<int> bytes = [];
    for (var command in tempCommands) {
      if (command is ImageCommand) {
        img.Image image = await _getImageFromUrl(command.imagePath);
        bytes += generator.image(image);
      } else if (command is EmptyLineCommand) {
        bytes += generator.feed(command.line);
      } else if (command is TextCommand) {
        bytes += generator.text(
          command.text,
          containsChinese: true,
          styles: command.style,
          linesAfter: command.linesAfter,
        );
      } else if (command is LineCommand) {
        bytes += generator.text(_textHelper.line());
      } else if (command is TextRowCommand) {
        bytes += generator.text(
          _textHelper.row(command.textList),
          styles: command.style,
          containsChinese: true,
        );
      } else if (command is OpenCashDrawerCommand) {
        bytes += generator.drawer();
      }
    }
    bytes += generator.cut();

    return bytes;
  }

  PrintCommands getStarPrintCommands() {
    _printCommands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);
    return _printCommands;
  }

  void addImage(String imagePath) {
    _printCommands.appendBitmap(
      path: imagePath,
      width: 576 ~/ 2,
      absolutePosition: (576 ~/ 2) ~/ 2,
      bothScale: true,
    );
    tempCommands.add(ImageCommand(imagePath));
  }

  void addEmptyLine({int line = 1}) {
    _printCommands.appendBitmapText(text: _textHelper.emptyLine(line: line));

    tempCommands.add(EmptyLineCommand(line));
  }

  void addTextLine(
    String text, {
    PosAlign alignment = PosAlign.left,
    bool bold = false,
    int linesAfter = 0,
    FontSizeType fontSizeType = FontSizeType.normal,
  }) {
    _printCommands.appendBitmapText(
        fontSize: _getFontSize(fontSizeType),
        text: _textHelper.text(text,
            alignment: alignment,
            linesAfter: linesAfter,
            fontSizeType: fontSizeType));

    tempCommands.add(
      TextCommand(
        text,
        style: PosStyles(
          height: _getFontPosTextSize(fontSizeType),
          width: _getFontPosTextSize(fontSizeType),
          align: alignment,
          bold: bold,
        ),
        linesAfter: linesAfter,
      ),
    );

    // _bytes += _generator!.text(
    //   text,
    //   containsChinese: true,
    //   styles: PosStyles(
    //     height: _getFontPosTextSize(fontSizeType),
    //     width: _getFontPosTextSize(fontSizeType),
    //     align: alignment,
    //     bold: bold,
    //   ),
    //   linesAfter: linesAfter,
    // );
  }

  void addLine() {
    _printCommands.appendBitmapText(text: _textHelper.line());

    tempCommands.add(LineCommand());

    // _bytes += _generator!.text(
    //   _textHelper.line(),
    // );
  }

  void addTextRow(
    List<TextColumn> textList, {
    int linesAfter = 0,
  }) {
    bool bold = textList.any((element) => element.bold);

    if (bold) {
      _printCommands
          .push({'appendEmphasis': _textHelper.row(textList, bold: bold)});
    } else {
      _printCommands.appendBitmapText(text: _textHelper.row(textList));
    }

    // List<PosColumn> posColumnList = textList.map((textColumn) {
    //   int max = 12;
    //   int totalR = textList.fold(0, (total, text) => total += text.ratio);
    //   int width = ((textColumn.ratio / totalR) * max).round();
    //   return textColumn.toPosColumn(width);
    // }).toList();

    tempCommands.add(TextRowCommand(textList, style: PosStyles(bold: bold)));
    // useless
    // _bytes += _generator!.row(posColumnList, multiLine: false);

    // _bytes += _generator!.text(_textHelper.row(textList),
    //     styles: PosStyles(bold: bold), containsChinese: true);
  }

  void openCashDrawer() {
    _printCommands.openCashDrawer(1);

    tempCommands.add(OpenCashDrawerCommand());
    // _bytes += _generator!.drawer();
  }

  Future<img.Image> _getImageFromUrl(String path) async {
    try {
      img.Image? image;

      final response = await http.get(Uri.parse(path));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        var compressedImage = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 558 ~/ 2,
          minWidth: 558 ~/ 2,
        );

        image = img.decodeImage(Uint8List.fromList(compressedImage));
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
