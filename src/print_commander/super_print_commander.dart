import 'dart:io';
import 'dart:typed_data';

import 'package:imin_printer/imin_printer.dart';

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

import '../utils/temp_command.dart';

enum FontSizeType { normal, big }

class SuperPrintCommander {
  final PType printerType;
  final PaperSize paperSize;
  final bool cutPaper;
  SuperPrintCommander({
    required this.printerType,
    this.paperSize = PaperSize.mm80,
    this.cutPaper = true,
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
        img.Image image = await _getImageFromUrl(
          command.imagePath,
          imageSize: command.imageSize,
        );
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
        bytes += generator.hr();
      } else if (command is TextRowCommand) {
        bytes += generator.text(
          _textHelper.row(command.textList),
          styles: command.style,
          containsChinese: true,
        );
      } else if (command is OpenCashDrawerCommand) {
        bytes += generator.drawer();
      } else if (command is QRCodeCommand) {
        bytes += generator.qrcode(
          command.qrCode,
          size: QRSize.size8,
        );
      }
    }
    if (cutPaper) {
      bytes += generator.cut();
    }

    return bytes;
  }

  PrintCommands getStarPrintCommands() {
    if (cutPaper) {
      _printCommands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);
    }
    return _printCommands;
  }

  void addImage(String imagePath, {double? iconSize}) {
    if (iconSize != null && iconSize == 0) return;
    const int paperWidth = 576;
    int centerPosition = (paperWidth ~/ 2);

    if (iconSize != null) {
      centerPosition = (paperWidth ~/ 2) - iconSize ~/ 2;
    }

    _printCommands.appendBitmap(
      path: imagePath,
      width: iconSize?.toInt() ?? (paperWidth ~/ 2),
      absolutePosition: centerPosition,
      bothScale: true,
    );

    tempCommands.add(ImageCommand(
      imagePath,
      imageSize: iconSize,
    ));
  }

  void addEmptyLine({int line = 1}) {
    _printCommands.push({'appendLineSpace': line});

    tempCommands.add(EmptyLineCommand(line));
  }

  void addTextLine(
    String text, {
    PosAlign alignment = PosAlign.left,
    bool bold = false,
    int linesAfter = 0,
    FontSizeType fontSizeType = FontSizeType.normal,
  }) {
    if (text.isEmpty) return;
    _printCommands.appendBitmapText(
      fontSize: _getFontSize(fontSizeType),
      text: _textHelper.text(
        text,
        alignment: alignment,
        linesAfter: linesAfter,
        fontSizeType: fontSizeType,
      ),
    );

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
      _printCommands.push({
        'appendEmphasis':
            _textHelper.row(textList, bold: bold, linesAfter: linesAfter),
      });
    } else {
      _printCommands.appendBitmapText(
        text: _textHelper.row(
          textList,
          linesAfter: linesAfter,
        ),
        fontSize: _getFontSize(FontSizeType.normal),
      );
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

    if (Platform.isAndroid) {
      () async {
        try {
          final iminPrinter = IminPrinter();
          await iminPrinter.initPrinter();
          await iminPrinter.openCashBox();
        } catch (e) {
          debugPrint('Failed to open imin cash drawer. $e.');
        }
      }();
    }
    // _bytes += _generator!.drawer();
  }

  void addQRCode(String qrCode) {
    _printCommands.push({
      'appendQrCode': qrCode,
      'absolutePosition': paperSize == PaperSize.mm80 ? 200 : 100,
    });

    tempCommands.add(QRCodeCommand(qrCode));
  }

  Future<img.Image> _getImageFromUrl(String path, {double? imageSize}) async {
    try {
      img.Image? image;

      final response = await http.get(Uri.parse(path));

      final int size = (imageSize ?? (558 ~/ 2)).toInt();

      print("receipt image size : $size");

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        final Uint8List compressedImage = Platform.isWindows
            ? bytes
            : await FlutterImageCompress.compressWithList(
                bytes,
                minHeight: size,
                minWidth: size,
              );

        image = img.decodeImage(Uint8List.fromList(compressedImage));
        if (Platform.isWindows) {
          image = img.copyResize(image!, width: size, height: size);
          image = img.grayscale(image);
        }
      } else {
        debugPrint('-----Failed to load image from url.');
      }

      return image!;
    } catch (e) {
      debugPrint('-----Failed to get image from url. $e.');
      rethrow;
    }
  }

  Future<Uint8List?> _getImageBytes(String path) async {
    try {
      final response = await http.get(Uri.parse(path));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        return bytes;
      } else {
        debugPrint('-----Failed to load image from url.');
      }
      return null;
    } catch (e) {
      debugPrint('-----Failed to get image from url. $e.');
      rethrow;
    }
  }

  int _getFontSize(FontSizeType fontSizeType) {
    if (paperSize == PaperSize.mm80) {
      switch (fontSizeType) {
        case FontSizeType.big:
          return 20;
        case FontSizeType.normal:
          return 12;
      }
    } else {
      switch (fontSizeType) {
        case FontSizeType.big:
          return 16;
        case FontSizeType.normal:
          return 8;
      }
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
