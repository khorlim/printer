import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tunaipro/extra_utils/printer/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/print_command_adapter.dart';
import 'package:tunaipro/extra_utils/printer/utils/text_column.dart';

class BeautyReceipt {
  static Future<PrintCommandAdapter> getReceipt(
      {PType printerType = PType.btPrinter}) async {
    PrintCommandAdapter printCommand =
        PrintCommandAdapter(printerType: printerType);

    final imagePath =
        "https://img.tunai.io/image/s3-f1d9b5f1-e780-4127-a397-a72e6cfdc1ab.jpeg";

    await printCommand.initialize(imagePath: imagePath);

    printCommand.addImage(imagePath);
    printCommand.addTextLine(
        'XSpakjdlksjflkdsjflksdjflksdjlfkjsldfkjsdlkfjslkfjlksdlksjflkdsj',
        alignment: PosAlign.center,
        linesAfter: 1);
    printCommand.addTextLine('RECEIPT',
        fontSizeType: FontSizeType.big,
        alignment: PosAlign.center,
        bold: true,
        linesAfter: 1);
    printCommand.addTextLine(
      'Name : Adam',
    );
    printCommand.addTextLine(
      'Mobile : 010101010100101',
    );
    printCommand.addTextLine(
      'Location : WonderLand',
    );
    printCommand.addTextLine(
      'ReceiptID : 000000035',
    );
    printCommand.addTextLine(
      'Date : 19/12/2023 5:28 pm (Tue)',
    );
    printCommand.addTextLine(
      'Date : 19/12/2023 5:28 sdjlfjdslkfjslkdjflskdjflksjflkjsdlkfjsldkjflskdjflksjdflkjsdlkfjlsk (Tue)',
    );
    printCommand.addLine();
    printCommand.addTextRow([
      TextColumn(
        text: 'Item Price',
        ratio: 1,
      ),
      TextColumn(
        text: 'Discount',
        ratio: 1,
      ),
      TextColumn(
        text: 'Qty',
        ratio: 1,
      ),
      TextColumn(text: 'Total', ratio: 1, alignment: PosAlign.right),
    ]);
    printCommand.addLine();
    printCommand.addTextRow([
      TextColumn(text: 'Item name', ratio: 1),
      TextColumn(text: 'Item name', ratio: 1, alignment: PosAlign.right)
    ]);
    printCommand.addTextRow([
      TextColumn(
        text: '17.70',
        ratio: 1,
      ),
      TextColumn(
        text: '5.00',
        ratio: 1,
      ),
      TextColumn(
        text: '1',
        ratio: 1,
      ),
      TextColumn(text: '100.00', ratio: 1, alignment: PosAlign.right),
    ]);

    return printCommand;
  }
}
