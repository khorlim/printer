// import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
// import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
// import 'package:tunaipro/engine/receipt/model/sub_models/r_field.dart';
// import 'package:tunaipro/engine/receipt/model/sub_models/r_item.dart';
// import 'package:tunaipro/extra_utils/printer/src/print_commander/super_print_commander.dart';
// import 'package:tunaipro/extra_utils/printer/src/receipt_commands/abstract_receipt.dart';

// // import '../utils/text_column.dart';

// // class WorkSlipReceipt extends AbstractReceipt {
// //   final ReceiptData receiptData;
// //   WorkSlipReceipt({
// //     required super.printerType,
// //     required super.paperSize,
// //     required this.receiptData,
// //   });

//   @override
//   SuperPrintCommander getPrintCommand({bool openDrawer = false}) {
//     printCommand.addTextLine('Job Order',
//         fontSizeType: FontSizeType.big,
//         alignment: PosAlign.center,
//         bold: true,
//         linesAfter: 2);

// //     printCommand.addTextLine('Name : ${receiptData.customerName}');

// //     if (receiptData.customerMobile != null) {
// //       printCommand.addTextLine('Mobile : ${receiptData.customerMobile!}');
// //     }

// //     addFieldLines(receiptData.field);

// //     if (receiptData.customerDetail != null) {
// //       printCommand
// //           .addTextLine('Car Model : ${receiptData.customerDetail!.carModel}');
// //       printCommand
// //           .addTextLine('Car Plate : ${receiptData.customerDetail!.carPlate}');
// //     }

// //     printCommand.addEmptyLine();

// //     addItemColumn(receiptData.items);

// //     printCommand.addEmptyLine(line: 2);

// //     return printCommand;
// //   }

// //   void addItemColumn(List<RItem> items, {int linesAfter = 0}) {
// //     printCommand.addLine();
// //     printCommand.addTextRow([
// //       TextColumn(
// //         text: 'Item Price',
// //         ratio: 3,
// //       ),
// //       TextColumn(
// //         text: 'Discount',
// //         ratio: 3,
// //       ),
// //       TextColumn(
// //         text: 'Qty',
// //         ratio: 1,
// //       ),
// //       TextColumn(text: 'Total', ratio: 2, alignment: PosAlign.right),
// //     ]);
// //     printCommand.addLine();
// //     for (var item in items) {
// //       if (item.description.isNotEmpty) {
// //         printCommand.addTextLine(item.description);
// //       }
// //       if (item.extra != null) {
// //         for (var extra in item.extra!) {
// //           printCommand.addTextLine(extra.description);
// //         }
// //       }
// //       printCommand.addEmptyLine();
// //       printCommand.addTextRow([
// //         TextColumn(
// //           text: item.price,
// //           ratio: 3,
// //         ),
// //         TextColumn(
// //           text: item.discount.toStringAsFixed(2),
// //           ratio: 3,
// //         ),
// //         TextColumn(
// //           text: item.qty.toString(),
// //           ratio: 1,
// //         ),
// //         TextColumn(text: item.amount, ratio: 2, alignment: PosAlign.right),
// //       ]);
// //       printCommand.addLine();
// //     }
// //   }

// //   void addFieldLines(List<RField> fields, {int linesAfter = 0}) {
// //     for (var field in fields) {
// //       printCommand.addTextLine('${field.title} : ${field.value}');
// //     }
// //     if (linesAfter > 0) {
// //       printCommand.addEmptyLine(line: linesAfter);
// //     }
// //   }
// // }
