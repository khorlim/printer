import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:imin_printer/imin_printer.dart';
import '../model/custom_printer_model.dart';
import '../utils/bit_map_text_helper.dart';
import '../utils/text_column.dart';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../printer_setting_screen/utils/receipt_icon_size_storage.dart';
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
  });

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
        if (command.imagePath.isNotEmpty) {
          try {
            img.Image image = await _getImageFromUrl(
              command.imagePath,
              imageSize: command.imageSize,
            );
            bytes += generator.image(image);
          } catch (e) {
            debugPrint('Failed to get image from url. $e.');
          }
        }
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

  /// Converts the print commands to a PDF document for preview
  Future<pw.Document> toPdf() async {
    final font = pw.Font.ttf(
      await rootBundle.load('asset/fonts/epson1.ttf'),
    );

    final doc = pw.Document();

    const double pageWidth = 150;

    // Convert paper width from mm to points
    const double dotsPerInch = 203.0;
    const double pointsPerInch = 72.0;

    final List<pw.Widget> widgets = [];

    for (var command in tempCommands) {
      if (command is ImageCommand && command.imagePath.isNotEmpty) {
        try {
          final img.Image rawImage = await _getImageFromUrl(
            command.imagePath,
            imageSize: command.imageSize,
          );

          final preparedImage = await _prepareImageForPdf(
            rawImage,
            command.imageSize,
          );

          final imageBytes = Uint8List.fromList(img.encodePng(preparedImage));

          // PDF width/height (logical pixels to points)
          final double sizePx = command.imageSize?.toDouble() ?? 100;
          final double pdfSizePoints = sizePx / (72.0 / 25.4);
          // optional: scale to fit page width

          widgets.add(
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                width: pdfSizePoints,
                height: pdfSizePoints,
              ),
            ),
          );
          widgets.add(_buildEmptyLine(font));
        } catch (e) {
          debugPrint('Failed to get image for PDF preview: $e');
        }
      } else if (command is EmptyLineCommand) {
        widgets.add(_buildEmptyLine(font));
      } else if (command is TextCommand) {
        widgets.add(
          _buildTextWidget(
            command.text,
            command.style,
            command.linesAfter,
            font,
          ),
        );
        widgets.add(_buildEmptyLine(font));
      } else if (command is LineCommand) {
        final fontSize = _getPdfFontSize(FontSizeType.normal);

        final int charsPerLine = _getMaxCharsPerLine();
        final String dashLine = List.filled(charsPerLine, '-').join();

        widgets.add(
          pw.Text(
            dashLine,
            style: pw.TextStyle(
              font: font,
              fontSize: fontSize,
            ),
          ),
        );
        widgets.add(_buildEmptyLine(font));
      } else if (command is TextRowCommand) {
        widgets.add(
          _buildTextRowWidget(
            command.textList,
            command.style,
            font,
          ),
        );
        widgets.add(_buildEmptyLine(font));
      } else if (command is QRCodeCommand) {
        // QR code size: typically 200 dots for 80mm, 100 dots for 58mm
        final double qrSizeDots = paperSize == PaperSize.mm80 ? 200.0 : 100.0;
        final double qrSizePoints = (qrSizeDots / dotsPerInch) * pointsPerInch;
        widgets.add(
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: command.qrCode,
              width: qrSizePoints,
              height: qrSizePoints,
            ),
          ),
        );
      }
      // OpenCashDrawerCommand is ignored for PDF preview
    }

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(pageWidth, double.infinity),
        margin: _receiptMargin(),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: widgets,
          );
        },
      ),
    );

    return doc;
  }

  pw.EdgeInsets _receiptMargin() {
    const double mmToPoints = 72.0 / 25.4;

    // Typical thermal margins
    const double horizontalMm = 3; // left & right
    const double verticalMm = 4; // top & bottom

    return const pw.EdgeInsets.symmetric(
      horizontal: horizontalMm * mmToPoints,
      vertical: verticalMm * mmToPoints,
    );
  }

  pw.Widget _buildEmptyLine(pw.Font font) {
    final height = _getLineHeightPoints(PosTextSize.size1);
    final fontSize = _getPdfFontSize(FontSizeType.normal);

    return pw.Text(
      '\n',
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
        height: (height / fontSize) / 2,
      ),
    );
  }

  double _getLineHeightPoints(PosTextSize size) {
    const double baseLineHeightDots = 24.0; // ESC/POS standard
    const double dotsPerInch = 203.0;
    const double pointsPerInch = 72.0;

    final double heightDots = baseLineHeightDots * size.value;
    return (heightDots / dotsPerInch) * pointsPerInch;
  }

  Future<img.Image> _prepareImageForPdf(
      img.Image src, double? targetSize) async {
    img.Image image = img.copyResize(
      src,
      width: targetSize?.toInt() ?? 558 ~/ 2, // match your generator sizing
      interpolation: img.Interpolation.linear,
    );

    // Mirror ESC/POS operations
    image = img.grayscale(image);

    return image;
  }

  pw.Widget _buildTextWidget(
    String text,
    PosStyles style,
    int linesAfter,
    pw.Font font,
  ) {
    final fontSize = _getPdfFontSize(style.height == PosTextSize.size2
        ? FontSizeType.big
        : FontSizeType.normal);

    final isBold = style.bold;
    final alignment = _getPdfAlignment(style.align);

    // Calculate exact line height
    final heightSize = style.height;
    final lineHeight = _getLineHeightPoints(heightSize);

    // Calculate spacing after text
    final double spacingAfter = linesAfter > 0
        ? _getLineHeightPoints(PosTextSize.size1) * linesAfter
        : 0;

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: spacingAfter),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          height: lineHeight / fontSize, // Exact line height
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignment,
      ),
    );
  }

  pw.Widget _buildTextRowWidget(
    List<TextColumn> textColumns,
    PosStyles style,
    pw.Font font,
  ) {
    if (textColumns.isEmpty) return pw.SizedBox.shrink();

    final fontSize = _getPdfFontSize(FontSizeType.normal);
    final isBold = style.bold;

    // Calculate exact line height
    final heightSize = style.height;
    final lineHeight = _getLineHeightPoints(heightSize);

    return pw.Text(
      _textHelper.row(textColumns),
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
        height: lineHeight / fontSize,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    );
  }

  /// Generates a PDF file from the print commands
  Future<File> generatePdfFile({String? fileName}) async {
    final doc = await toPdf();
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/${fileName ?? 'receipt_preview_${DateTime.now().millisecondsSinceEpoch}'}.pdf',
    );
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  pw.TextAlign _getPdfAlignment(PosAlign align) {
    return switch (align) {
      PosAlign.left => pw.TextAlign.left,
      PosAlign.center => pw.TextAlign.center,
      PosAlign.right => pw.TextAlign.right,
    };
  }

  PrintCommands getStarPrintCommands() {
    if (cutPaper) {
      _printCommands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);
    }
    return _printCommands;
  }

  void addImage(String imagePath, {double? iconSize}) {
    final ReceiptIconSizeStorage iconSizeStorage = ReceiptIconSizeStorage();
    final settingIconSize = iconSizeStorage.fetch() ?? ReceiptIconSize.medium;

    final realIconSize = iconSize ?? settingIconSize.size;

    if (realIconSize == 0) return;

    const int paperWidth = 576;
    int centerPosition = (paperWidth ~/ 2) - realIconSize ~/ 2;

    if (imagePath.isNotEmpty) {
      _printCommands.appendBitmap(
        path: imagePath,
        width: realIconSize.toInt(),
        absolutePosition: centerPosition,
        bothScale: true,
      );
      tempCommands.add(ImageCommand(
        imagePath,
        imageSize: realIconSize,
      ));
    }
  }

  void addEmptyLine({int line = 1}) {
    _printCommands.appendLineFeed(line);

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
    _printCommands.appendBitmapText(
      fontSize: _getFontSize(FontSizeType.normal),
      text: _textHelper.line(),
    );

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

  int _getMaxCharsPerLine({PosFontType? fontType}) {
    final font = fontType ?? PosFontType.fontA;
    return switch (paperSize) {
      PaperSize.mm58 => (font == PosFontType.fontA) ? 32 : 42,
      PaperSize.mm72 => (font == PosFontType.fontA) ? 42 : 56,
      PaperSize.mm80 => (font == PosFontType.fontA) ? 48 : 64,
      _ => 48,
    };
  }

  double _getPdfFontSize(FontSizeType fontSizeType) {
    const double baseCharWidthDots = 12.0;

    final double scale = fontSizeType == FontSizeType.big ? 2.0 : 1.0;

    const double dotsPerInch = 203.0;
    const double pointsPerInch = 72.0;

    final double charWidthDots = baseCharWidthDots * scale;
    return (charWidthDots / dotsPerInch) * pointsPerInch;
  }
}
