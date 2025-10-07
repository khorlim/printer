import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:imin_printer/enums.dart';
import 'package:imin_printer/imin_printer.dart';
import 'package:imin_printer/imin_style.dart';

import '../model/custom_printer_model.dart';
import '../print_commander/super_print_commander.dart';
import '../utils/bit_map_text_helper.dart';
import '../utils/temp_command.dart';

class IminPrinterHelper {
  static final IminPrinter iminPrinter = IminPrinter();

  static Future<CustomPrinter?> searchForIminPrinter() async {
    bool status = await checkStatus();
    if (status) {
      return const CustomPrinter(
        name: 'Imin Printer',
        address: '',
        printerType: PType.imin,
      );
    }
    return null;
  }

  static Future<bool> checkStatus() async {
    try {
      final status = await iminPrinter.getPrinterStatus();
      final statusCode = status['code'];
      return statusCode == '0' || statusCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> startPrint(SuperPrintCommander commands) async {
    try {
      final BitmapTextHelper _textHelper = BitmapTextHelper(
        printerType: commands.printerType,
        paperSize: commands.paperSize,
      );

      await iminPrinter.setTextLineSpacing(0);

      for (var command in commands.tempCommands) {
        if (command is ImageCommand) {
          // if (command.imagePath.isNotEmpty) {
          //   try {
          //     img.Image image = await _getImageFromUrl(
          //       command.imagePath,
          //       imageSize: command.imageSize,
          //     );
          //     bytes += generator.image(image);
          //   } catch (e) {
          //     debugPrint('Failed to get image from url. $e.');
          //   }
          // }
        } else if (command is EmptyLineCommand) {
          for (var i = 0; i < command.line; i++) {
            await iminPrinter.printAndFeedPaper(5);
          }
        } else if (command is TextCommand) {
          await iminPrinter.printText(
            command.text,
            style: IminTextStyle(
              align: switch (command.style.align) {
                PosAlign.left => IminPrintAlign.left,
                PosAlign.center => IminPrintAlign.center,
                PosAlign.right => IminPrintAlign.right,
              },
              fontStyle: command.style.bold ? IminFontStyle.bold : null,
            ),
          );

          // bytes += generator.text(
          //   command.text,
          //   containsChinese: true,
          //   styles: command.style,
          //   linesAfter: command.linesAfter,
          // );
        } else if (command is LineCommand) {
          await iminPrinter.printText(_textHelper.line());
        } else if (command is TextRowCommand) {
          await iminPrinter.printText(
            _textHelper.row(command.textList),
          );

          // bytes += generator.text(
          //   _textHelper.row(command.textList),
          //   styles: command.style,
          //   containsChinese: true,
          // );
        } else if (command is OpenCashDrawerCommand) {
          await iminPrinter.openCashBox();
        } else if (command is QRCodeCommand) {
          await iminPrinter.printQrCode(
            command.qrCode,
          );
        }
      }
      if (commands.cutPaper) {
        await iminPrinter.partialCut();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
